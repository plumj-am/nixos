def print-notify [message: string] {
    print $"[Theme Switch]: ($message)"
    if (which dunstify | is-not-empty) {
        if ($message | str downcase | str contains "error") {
            ^dunstify --appname="Theme Switch" --urgency=critical --timeout=30000 "Error" $"($message)"
        } else {
            ^dunstify --appname="Theme Switch" "Status" $"($message)"
        }
    }
}

def toggle-theme [theme?: string] {
    let dark_mode_file = $"($env.HOME)/.config/dark-mode"

    # Use provided theme.
    let new_theme = if $theme in ["light", "dark"] {
        $theme
    } else {
        print-notify $"Invalid theme: '($theme)'. Use 'light' or 'dark'."
        return
    }

    print-notify $"Switching to ($new_theme) theme."

    # Use NixOS specialisations for theme switching.
    # Always switch to base system first, then to target specialisation if needed.
    try {
        ^sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

        print-notify $"Activating ($new_theme) specialisation."
        if $new_theme == "dark" {
            ^sudo /run/current-system/specialisation/dark-theme/bin/switch-to-configuration switch
        } else {
            ^sudo /run/current-system/specialisation/light-theme/bin/switch-to-configuration switch
        }

    } catch { |e|
        print-notify $"Error when switching theme: ($e.msg)"
        return
    }

    # Update system dark mode marker and environment variable.
    if $new_theme == "dark" {
        touch $dark_mode_file
        $env.THEME_MODE = "dark"
        print-notify "Dark mode activated."
    } else {
        if ($dark_mode_file | path exists) {
            rm $dark_mode_file
        }
        $env.THEME_MODE = "light"
        print-notify "Light mode activated."
    }

    print-notify $"Theme switch to ($new_theme) completed!"
}
