{ lib, ... }:
let
  inherit (lib) mkOption types;

  # global theme configuration - use `tt dark` or `tt light` to switch
  is_dark = false;

  themes = {
    nvim.dark       = "gruvbox-material";
    nvim.light      = "gruvbox-material";

    alacritty.dark  = "gruber_darker";
    alacritty.light = "gruvbox_material_medium_light";

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
  };

  # helpers
  get_theme = program: if is_dark then themes.${program}.dark else themes.${program}.light;
  variant   = if is_dark then "dark" else "light";
in
{
  # define theme as a top-level option that all modules can access via config.theme
  options.theme = mkOption {
    type        = types.attrs;
    default     = {};
    description = "Global theme configuration";
  };

  # set the theme values
  config.theme = {
    # core theme state
    is_dark = is_dark;
    variant = variant;

    # program-specific theme names
    nvim      = get_theme "nvim";
    alacritty = get_theme "alacritty";
    zellij    = get_theme "zellij";
    starship  = get_theme "starship";
    vivid     = get_theme "vivid";
    nushell   = get_theme "nushell";
    helix     = get_theme "helix";

    # expose raw theme definitions for flexibility
    themes = themes;
  };

  # export theme info as env var
  config.environment.variables.THEME_MODE = variant;
}
