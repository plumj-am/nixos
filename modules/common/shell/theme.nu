def toggle-theme [theme?: string] {
    let dark_mode_file = $"($env.HOME)/.config/dark-mode"

    # determine current theme from nix theme file
    let theme_file = $"($env.HOME)/nixos-config/modules/common/theme.nix"
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
        if $current_theme == "light" { "dark" } else { "light" }
    }

    print $"Switching from ($current_theme) to ($new_theme) theme..."

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
        print $"failed to update theme: ($e.msg)"
        return
    }

    # update system dark mode marker
    if $new_theme == "dark" {
        touch $dark_mode_file
        $env.THEME_MODE = "dark"
        print "dark mode activated"
    } else {
        if ($dark_mode_file | path exists) {
            rm $dark_mode_file
        }
        $env.THEME_MODE = "light"
        print "light mode activated"
    }
        # rebuild nixos config to apply themes
        print "Rebuilding nixos config to apply themes... (this may take a moment)"
        nu $"($env.HOME)/nixos-config/rebuild.nu"

    print "Theme switch completed!"
}

# check current theme
def current-theme [] {
    let theme_file = $"($env.HOME)/nixos-config/modules/common/theme.nix"
    try {
        let content = open $theme_file
        if ($content | str contains "is_dark = true;") {
            "dark"
        } else {
            "light"
        }
    } catch {
        "light"
    }
}
