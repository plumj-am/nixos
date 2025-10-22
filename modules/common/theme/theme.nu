def print-notify [message: string, progress: int = -1] {
    print $"(ansi purple)[Theme Switcher] ($message)"
    if (which notify-send | is-not-empty) {
        # Progress notifications persist, completion/error notifications auto-dismiss.
        let is_complete = $progress == 100
        let is_error = ($message | str downcase | str contains "error")

        # Dismiss all previous notifications before showing completion.
        if $is_complete and (which makoctl | is-not-empty) {
            ^makoctl dismiss --all
        }

        let timeout = if $is_error {
            30000
        } else if $is_complete {
            5000
        } else {
            0  # Persist until replaced.
        }

        let urgency = if $is_error { "critical" } else { "normal" }

        let args = if $progress >= 0 and $progress < 100 {
            ["--hint" $"int:value:($progress)"]
        } else {
            []
        }

        ^notify-send ...$args --urgency=($urgency) --expire-time=($timeout) "Theme Switcher" $"($message)"
    }
}

def generate-pywal-colors [wallpaper: string, is_dark: bool] {
    # Clear pywal cache to force regeneration.
    ^rm -rf ~/.cache/wal

    # Build args: start with base args, then append mode-specific ones.
    let base_args = ["-n" "--backend" "wal" "-i" $wallpaper]
    let mode_args = if $is_dark {
        ["--saturate" "0.5"]
    } else {
        ["--saturate" "0.75" "-l"]
    }

    ^wal ...($base_args | append $mode_args) err> /dev/null
    ^cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/modules/common/theme/pywal-colors.json"
}

def toggle-theme [theme?: string] {
    # Determine current theme and scheme from theme.json file.
    let theme_json_path = $"($env.HOME)/nixos/modules/common/theme/theme.json"
    let theme_config = try {
        open $theme_json_path
    } catch {
        { mode: "light", scheme: "pywal" }
    }

    let current_theme = $theme_config.mode
    let using_pywal = $theme_config.scheme == "pywal"

    # Use provided theme or error if not provided.
    let new_theme = if $theme != null {
        if $theme in ["light", "dark"] {
            $theme
        } else {
            print-notify $"Invalid theme: '($theme)'. Use 'light' or 'dark'."
            return
        }
    } else {
        print-notify "Theme argument required. Use 'light' or 'dark'."
        return
    }

    print-notify $"Switching to ($new_theme) theme."

    # If using pywal, regenerate colors from current wallpaper.
    if $using_pywal {
        print-notify "Regenerating pywal colors..." 20

        let wallpaper = try {
            ^swww query | lines | first | parse "{monitor}: image: {path}" | get path.0
        } catch {
            null
        }

        if $wallpaper != null and ($wallpaper | path exists) {
            try {
                generate-pywal-colors $wallpaper ($new_theme == "dark")
                print-notify $"Regenerated ($new_theme) mode pywal colors." 30
            } catch { |e|
                print-notify $"Warning: Failed to regenerate pywal colors: ($e.msg)" 30
            }
        } else {
            print-notify "Warning: Could not detect current wallpaper" 30
        }
    }

    # Update theme.json with new configuration.
    print-notify "Updating theme configuration..." 40
    $env.THEME_MODE = $new_theme

    let theme_json = $"($env.HOME)/nixos/modules/common/theme/theme.json"
    { mode: $new_theme, scheme: $theme_config.scheme } | to json | save $theme_json --force

    print-notify $"($new_theme | str capitalize) mode activated." 50

    # Rebuild configuration to apply themes.
    print-notify $"Rebuilding configuration to apply ($new_theme) theme." 75

    try {
        ^rebuild --quiet
    } catch { |e|
        print-notify "Error: Rebuild failed, run manually in a terminal."
        exit 1
    }

    print-notify $"Switch to the ($new_theme) theme completed!" 100
}

def switch-scheme [scheme: string] {
    # Validate scheme.
    if $scheme not-in ["pywal", "gruvbox"] {
        print-notify $"Invalid scheme: '($scheme)'. Use 'pywal' or 'gruvbox'."
        return
    }

    print-notify $"Switching to ($scheme) color scheme."

    # Get current theme configuration from theme.json file.
    let theme_json_path = $"($env.HOME)/nixos/modules/common/theme/theme.json"
    let theme_config = try {
        open $theme_json_path
    } catch {
        { mode: "light", scheme: "pywal" }
    }

    # If switching to pywal, generate colors from current wallpaper.
    if $scheme == "pywal" {
        print-notify "Generating pywal colors from current wallpaper..." 25

        let is_dark = $theme_config.mode == "dark"

        let wallpaper = try {
            ^swww query | lines | first | parse "{monitor}: image: {path}" | get path.0
        } catch {
            null
        }

        if $wallpaper != null and ($wallpaper | path exists) {
            try {
                generate-pywal-colors $wallpaper $is_dark
                print-notify "Generated pywal colors." 50
            } catch { |e|
                print-notify $"Warning: Failed to generate colors: ($e.msg)" 50
            }
        } else {
            print-notify "Warning: Could not detect current wallpaper" 50
        }
    }

    # Update theme.json with new configuration.
    $env.THEME_SCHEME = $scheme

    let theme_json = $"($env.HOME)/nixos/modules/common/theme/theme.json"
    { mode: $theme_config.mode, scheme: $scheme } | to json | save $theme_json --force

    print $"Updated THEME_SCHEME to ($scheme)"

    # Rebuild configuration to apply new scheme.
    print-notify $"Rebuilding configuration to apply ($scheme) scheme..." 75

    try {
        ^rebuild --quiet
    } catch { |e|
        print-notify "Error: Rebuild failed, run manually in a terminal."
        exit 1
    }

    print-notify $"Switch to ($scheme) scheme completed!" 100
}

# Main tt command - handles both light/dark and scheme switching.
export def tt [arg?: string] {
    if $arg == null {
        print "Usage: tt <dark|light|pywal|gruvbox>"
        return
    }

    match $arg {
        "dark" | "light" => { toggle-theme $arg }
        "pywal" | "gruvbox" => { switch-scheme $arg }
        _ => { print $"Invalid option: '($arg)'. Use: dark, light, pywal, or gruvbox." }
    }
}
