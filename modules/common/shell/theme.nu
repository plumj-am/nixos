def print-notify [message: string, progress: int = -1] {
    print $"(ansi purple)[Theme Switcher] ($message)"
    if (which dunstify | is-not-empty) {
        let base_args = ["--appname=Theme Switcher" "--replace=1002"]
        let args = if $progress >= 0 {
            $base_args | append ["--hints" $"int:value:($progress)"]
        } else {
            $base_args
        }

        # Use persistent notifications (timeout=0) when in-progress.
        # Use short timeout for completion messages (progress=100).
        let timeout = if $progress >= 0 and $progress < 100 { 0 } else { 15000 }

        if ($message | str downcase | str contains "error") {
            ^dunstify ...$args --urgency=critical --timeout=30000 "Theme Switcher" $"($message)"
        } else {
            ^dunstify ...$args --urgency=normal --timeout=($timeout) "Theme Switcher" $"($message)"
        }
    }
}

def toggle-theme [theme?: string] {
    let dark_mode_file = $"($env.HOME)/.config/dark-mode"

    # Determine current theme from nix theme file.
    let theme_file = $"($env.HOME)/nixos/modules/common/theme.nix"
    let current_theme = try {
        let content = open $theme_file
        if ($content | str contains "is_dark = true;") {
            "dark"
        } else {
            "light"
        }
    } catch {
        "light"
    }

    # Use provided theme or toggle current.
    let new_theme = if $theme != null {
        if $theme in ["light", "dark"] {
            $theme
        } else {
            print $"Invalid theme: ($theme). Use 'light' or 'dark'"
            return
        }
    } else {
        print-notify $"Invalid theme: '($theme)'. Use 'light' or 'dark'."
        return
    }

    print-notify $"Switching to ($new_theme) theme."

    # Update centralized theme file.
    try {
        let content = open $theme_file

        let updated = if $new_theme == "dark" {
            $content | str replace "is_dark = false;" "is_dark = true;"
        } else {
            $content | str replace "is_dark = true;" "is_dark = false;"
        }

        $updated | save $theme_file --force
        print $"updated theme to ($new_theme)"
    } catch { |e|
        print-notify $"Failed to switch theme: ($e.msg)"
        return
    }

    # Update system dark mode marker and environment variable.
    print-notify "Updating environment..." 25
    if $new_theme == "dark" {
        touch $dark_mode_file
        $env.THEME_MODE = "dark"
        print-notify "Dark mode activated." 25
    } else {
        if ($dark_mode_file | path exists) {
            rm $dark_mode_file
        }
        $env.THEME_MODE = "light"
        print-notify "Light mode activated." 25
    }

    # Rebuild configuration to apply themes.
    print-notify $"Rebuilding configuration to apply ($new_theme) theme." 50

    try {
        nu $"($env.HOME)/rebuild.nu" --quiet
    } catch { |e|
        print-notify "Error: Rebuild failed, run manually in a terminal." 100
        exit 1
    }

    # Using `hyprpaper` now in `modules/linux/hyprland.nix`.
    # Switch wallpaper to the new theme.
    # let wallpaper_success: bool = switch-wallpaper $new_theme

    # if $wallpaper_success {
    #     print-notify $"Wallpaper switch for the ($new_theme) theme succeeded." 75
    # } else {
    #     print-notify $"Wallpaper switch failed, continuing with theme switch." 75
    # }

    print-notify $"Switch to the ($new_theme) theme completed!" 100
}
