def toggle-theme [theme?: string] {
    let dark_mode_file = $"($env.HOME)/.config/dark-mode"

    # Use provided theme.
    let new_theme = if $theme in ["light", "dark"] {
        $theme
    } else {
        print_notify $"Invalid theme: '($theme)'. Use 'light' or 'dark'."
        return
    }

    print_notify $"Switching to ($new_theme) theme."

    # Use NixOS specialisations for theme switching.
    # Always switch to base system first, then to target specialisation if needed.
    try {
        ^sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

        print_notify $"Activating ($new_theme) specialisation."
        if $new_theme == "dark" {
            ^sudo /run/current-system/specialisation/dark-theme/bin/switch-to-configuration switch
        } else {
            ^sudo /run/current-system/specialisation/light-theme/bin/switch-to-configuration switch
        }

    } catch { |e|
        print_notify $"Failed to switch theme: ($e.msg)"
        return
    }

    # Update system dark mode marker and environment variable.
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

    print_notify($"Theme switch to ($new_theme) completed!")
}

def print_notify [message: string] {
    print $"[Theme Switcher]: ($message)"
    if (which dunstify | is-not-empty) {
        ^dunstify "[Theme Switcher]" $"($message)"
    }

}
