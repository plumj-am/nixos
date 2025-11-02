{ pkgs, config, ... }:
let
  inherit (config.theme) is_dark;

  themes = {
    alacritty.dark  = "gruvbox_material_hard_dark";
    alacritty.light = "gruvbox_material_hard_light";

    ghostty.dark  = "Gruvbox Dark Hard";
    ghostty.light = "Gruvbox Light Hard";

    zellij.dark     = "gruvbox-dark";
    zellij.light    = "gruvbox-light";

    starship.dark   = "dark_theme";
    starship.light  = "light_theme";

    vivid.dark      = "gruvbox-dark";
    vivid.light     = "gruvbox-light";

    nushell.dark    = "dark-theme";
    nushell.light   = "light-theme";

    helix.dark      = "gruvbox_dark_hard";
    helix.light     = "gruvbox_light_hard";

    gtk.dark = {
      name    = "Gruvbox-Dark";
      package = pkgs.gruvbox-gtk-theme;
    };
    gtk.light = {
      name    = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };

    qt.dark = {
      name          = "adwaita-dark";
      platformTheme = "adwaita";
    };
    qt.light = {
      name          = "adwaita";
      platformTheme = "adwaita";
    };

    icons.dark = {
      name    = "Gruvbox-Plus-Dark";
      package = pkgs.gruvbox-plus-icons;
    };
    icons.light = {
      name    = "Papirus-Light";
      package = pkgs.papirus-icon-theme;
    };
  };

  # Helper for the current theme.
  get_theme = program: if is_dark then themes.${program}.dark else themes.${program}.light;
in
{
  config.theme = {
    icons = get_theme "icons";

    # Program-specific theme names.
    alacritty = get_theme "alacritty";
    ghostty   = get_theme "ghostty";
    zellij    = get_theme "zellij";
    starship  = get_theme "starship";
    vivid     = get_theme "vivid";
    nushell   = get_theme "nushell";
    helix     = get_theme "helix";
    gtk       = get_theme "gtk";
    qt        = get_theme "qt";

    # Expose raw theme definitions for flexibility.
    themes = themes;
  };
}
