def toggle-theme [theme?: string] {
    let nvim_source_file = $"($env.HOME)/nixos-config/home/modules/editor/nvim/set_colorscheme.lua"
	let zellij_config_file = $"($env.HOME)/nixos-config/home/modules/programs/zellij.nix"
    let starship_config_file = $"($env.HOME)/nixos-config/home/modules/shell/starship.nix"
    let dark_mode_file = $"($env.HOME)/.config/dark-mode"

    # determine current theme from source file
    let current_theme = try {
        let content = open $nvim_source_file
        if ($content | str contains "local current_theme = dark_theme") {
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

    # skip if already the desired theme
    # if $current_theme == $new_theme {
    #     print $"Already in ($current_theme) mode"
    #     return
    # }

    print $"Switching from ($current_theme) to ($new_theme) theme..."

    # update neovim source file in dotfiles
    try {
        let content = open $nvim_source_file
        let updated = $content | str replace --regex 'local current_theme = \w+_theme' $'local current_theme = ($new_theme)_theme'
        $updated | save $nvim_source_file --force
        print $"updated nvim source to ($new_theme)_theme"
    } catch { |e|
        print $"failed to update nvim theme: ($e.msg)"
        return
    }

    # update zellij theme
    try {
        let content = open $zellij_config_file
        let updated = $content | str replace --regex 'theme = \w+_theme;' $'theme = ($new_theme)_theme;'
		$updated | save $zellij_config_file --force
        print $"updated zellij source to ($new_theme)_theme"
    } catch { |e|
        print $"failed to update zellij theme: ($e.msg)"
        return
    }

    # update starship theme
    try {
        let content = open $starship_config_file
        let updated = $content | str replace --regex 'palette = "\w+_theme";' $'palette = "($new_theme)_theme";'
        $updated | save $starship_config_file --force
        print $"updated starship source to ($new_theme)_theme"
    } catch { |e|
        print $"failed to update starship theme: ($e.msg)"
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
        # rebuild nixos config to apply nvim theme
        print "Rebuilding nixos config to apply nvim theme... (this may take a moment)"
        sudo nixos-rebuild switch --flake /home/james/nixos-config#nixos-wsl

    print "Theme switch completed!"
}

# check current theme
def current-theme [] {
    let nvim_source_file = $"($env.HOME)/nixos-config/home/modules/editor/nvim/set_colorscheme.lua"
    try {
        let content = open $nvim_source_file
        if ($content | str contains "local current_theme = dark_theme") {
            "dark"
        } else {
            "light"
        }
    } catch {
        "light"
    }
}
