def print-notify [message: string, progress: int = -1] {
    print $"[Theme Switch]: ($message)"
    if (which dunstify | is-not-empty) {
        let base_args = ["--appname=Theme Switch" "--replace=1002"]
        let args = if $progress >= 0 {
            $base_args | append ["--hints" $"int:value:($progress)"]
        } else {
            $base_args
        }

        if ($message | str downcase | str contains "error") {
            ^dunstify ...$args --urgency=critical --timeout=30000 "Error" $"($message)"
        } else {
            ^dunstify ...$args --urgency=normal --timeout=30000 "Status" $"($message)"
        }
    }
}

def toggle-theme [theme?: string] {
    let dark_mode_file = $"($env.HOME)/.config/dark-mode"

    # determine current theme from nix theme file
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

    # use provided theme or toggle current
    let new_theme = if $theme != null {
        if $theme in ["light", "dark"] {
            $theme
        } else {
            print $"Invalid theme: ($theme). Use 'light' or 'dark'"
            return
        }
    } else {
        print_notify $"Invalid theme: '($theme)'. Use 'light' or 'dark'."
        return
    }

    print_notify $"Switching to ($new_theme) theme."

    # update centralized theme file
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
        print_notify $"Failed to switch theme: ($e.msg)"
        return
    }

    # Update system dark mode marker and environment variable.
    print-notify "Updating environment..." 75
    if $new_theme == "dark" {
        touch $dark_mode_file
        $env.THEME_MODE = "dark"
        print_notify "Dark mode activated."
    } else {
        if ($dark_mode_file | path exists) {
            rm $dark_mode_file
        }
        $env.THEME_MODE = "light"
        print_notify "Light mode activated."
    }
    # rebuild nixos config to apply themes
    print "Rebuilding nixos config to apply themes... (this may take a moment)"
    nu $"($env.HOME)/rebuild.nu"

    print-notify $"Theme switch to ($new_theme) completed!" 100
}

def print_notify [message: string] {
    print $"[Theme Switcher]: ($message)"
    if (which dunstify | is-not-empty) {
        ^dunstify "[Theme Switcher]" $"($message)"
    }
}
