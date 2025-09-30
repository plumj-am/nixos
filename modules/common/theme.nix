{ lib, pkgs, config, ... }:
let
  inherit (lib) mkOption types mkIf;

  # Global theme configuration - can be overridden by specialisations.
  is_dark = if config.themeOverride != null
           then config.themeOverride
           else false;  # Default to light.

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
    vivid.dark      = "gruvbox-dark-hard";
    vivid.light     = "gruvbox-light-hard";

    nushell.dark    = "dark-theme";
    nushell.light   = "light-theme";

    helix.dark      = "gruvbox_dark_hard";
    helix.light     = "gruvbox_light_hard";

    gtk.dark = {
      name    = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
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
      name    = "Gruvbox-Plus-Light";
      package = pkgs.gruvbox-plus-icons;
    };
  };

  # Helpers.
  get_theme = program: if is_dark then themes.${program}.dark else themes.${program}.light;
  variant   = if is_dark then "dark" else "light";
in
{
  # Define theme as a top-level option that all modules can access via config.theme.
  options.theme = mkOption {
    type        = types.attrs;
    default     = {};
    description = "Global theme configuration";
  };

  # Separate option for specialisation override.
  options.themeOverride = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Force dark or light theme (used by specialisations)";
  };

  # Set the theme values.
  config.theme = {
    # Core theme state.
    is_dark = is_dark;
    variant = variant;

    # Base16 color scheme.
    inherit colors;

    # Color helpers with prefixes.
    withHash    = lib.mapAttrs (name: value: "#${value}") colors;
    with0x      = lib.mapAttrs (name: value: "0x${value}") colors;

    # Shared design system.
    radius  = 4;
    border  = 2;
    margin  = 8;
    padding = 8;

    # Font configuration.
    font = {
      size.small  = 12;
      size.normal = 16;
      size.big    = 20;

      mono.name    = "JetBrainsMono Nerd Font";
      mono.family  = "JetBrainsMono Nerd Font Mono";
      mono.package = pkgs.nerd-fonts.jetbrains-mono;

      sans.name    = "Lexend";
      sans.package = pkgs.lexend;
    };

    icons = get_theme "icons";


    # Program-specific theme names.
    vivid     = get_theme "vivid";
    nushell   = get_theme "nushell";
    helix     = get_theme "helix";
    gtk       = get_theme "gtk";
    qt        = get_theme "qt";

    # Expose raw theme definitions for flexibility.
    themes = themes;
  };

  # Export theme info as environment variable.
  config.environment.variables.THEME_MODE        = variant;
  config.environment.sessionVariables.THEME_MODE = variant;

  config.home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    xdg.desktopEntries.dark-mode = {
      name     = "Dark Mode";
      exec     = ''nu -l -c "tt dark"'';
      terminal = false;
    };
    xdg.desktopEntries.light-mode = {
      name     = "Light Mode";
      exec     = ''nu -l -c "tt light"'';
      terminal = false;
    };
  }];

}
