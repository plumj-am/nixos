{ lib, ... }:
let
  inherit (lib) mkOption types;

  # Global theme configuration - use `tt dark` or `tt light` to switch.
  is_dark = true;

  # Gruvbox hard Base16 color definitions.
  gruvbox_colors = {
    dark = {
      base00 = "1d2021"; # Background.
      base01 = "3c3836"; # Background 1.
      base02 = "504945"; # Background 2.
      base03 = "665c54"; # Background 3.
      base04 = "bdae93"; # Foreground 2.
      base05 = "d5c4a1"; # Foreground 1.
      base06 = "ebdbb2"; # Foreground 0.
      base07 = "fbf1c7"; # Foreground.
      base08 = "fb4934"; # Red.
      base09 = "fe8019"; # Orange.
      base0A = "fabd2f"; # Yellow.
      base0B = "b8bb26"; # Green.
      base0C = "8ec07c"; # Aqua.
      base0D = "83a598"; # Blue.
      base0E = "d3869b"; # Purple.
      base0F = "d65d0e"; # Brown.
    };
    light = {
      base00 = "f9f5d7"; # Background.
      base01 = "ebdbb2"; # Background 1.
      base02 = "d5c4a1"; # Background 2.
      base03 = "bdae93"; # Background 3.
      base04 = "665c54"; # Foreground 2.
      base05 = "504945"; # Foreground 1.
      base06 = "3c3836"; # Foreground 0.
      base07 = "282828"; # Foreground.
      base08 = "9d0006"; # Red.
      base09 = "af3a03"; # Orange.
      base0A = "b57614"; # Yellow.
      base0B = "79740e"; # Green.
      base0C = "427b58"; # Aqua.
      base0D = "076678"; # Blue.
      base0E = "8f3f71"; # Purple.
      base0F = "d65d0e"; # Brown.
    };
  };

  # Current color scheme.
  colors = if is_dark then gruvbox_colors.dark else gruvbox_colors.light;

  themes = {
    nvim.dark       = "gruvbox-material";
    nvim.light      = "gruvbox-material";

    alacritty.dark  = "gruvbox_material_hard_dark";
    alacritty.light = "gruvbox_material_hard_light";

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

  # Set the theme values.
  config.theme = {
    # Core theme state.
    is_dark = is_dark;
    variant = variant;

    # Base16 color scheme.
    inherit colors;

    # Color helpers with prefixes.
    withHashtag = lib.mapAttrs (name: value: "#${value}") colors;
    with0x      = lib.mapAttrs (name: value: "0x${value}") colors;

    # Design tokens.
    cornerRadius = 4;
    borderWidth = 2;
    margin = 8;
    padding = 8;

    # Font configuration.
    font = {
      size = {
        normal = 16;
        big = 20;
        small = 12;
      };
      mono = {
        name = "JetBrainsMono Nerd Font";
        family = "JetBrainsMono Nerd Font Mono";
      };
    };

    # Program-specific theme names.
    nvim      = get_theme "nvim";
    alacritty = get_theme "alacritty";
    zellij    = get_theme "zellij";
    starship  = get_theme "starship";
    vivid     = get_theme "vivid";
    nushell   = get_theme "nushell";
    helix     = get_theme "helix";

    # Expose raw theme definitions for flexibility.
    themes = themes;
  };

  # Export theme info as env var.
  config.environment.variables.THEME_MODE = variant;
}
