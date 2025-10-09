{ lib, self, ... }:
let
  # Global theme configuration - use `tt dark`/`tt light` to switch light/dark.
  # Use `tt pywal`/`tt gruvbox` to switch color scheme.
  is_dark = if builtins.pathExists (self + /modules/common/theme/dark-mode) then true else false;
  color_scheme = "pywal"; # "gruvbox" or "pywal"

  # Pywal colors cache - single file updated when theme changes.
  # Stored in flake directory so Nix can access it (Nix can't read ~/.cache).
  pywal_cache = self + /pywal-colors.json;

  # Parse pywal colors and convert to base16 format.
  # Pywal provides: background, foreground, color0-15.
  parse_pywal_colors = json: let
    colors = builtins.fromJSON json;
    strip_hash = s: builtins.substring 1 6 s;
  in {
    base00 = strip_hash colors.colors.color0;  # Background 0.
    base01 = strip_hash colors.colors.color1;  # Background 1.
    base02 = strip_hash colors.colors.color2;  # Background 2.
    base03 = strip_hash colors.colors.color3;  # Background 3.
    base04 = strip_hash colors.colors.color4;  # Foreground 3.
    base05 = strip_hash colors.colors.color5; # Foreground 2.
    base06 = strip_hash colors.colors.color6; # Foreground 1.
    base07 = strip_hash colors.colors.color7;  # Foreground 0.
    base08 = strip_hash colors.colors.color8;  # Main colour 1.
    base09 = strip_hash colors.colors.color9;  # Main colour 2.
    base0A = strip_hash colors.colors.color10;  # Main colour 3.
    base0B = strip_hash colors.colors.color11;  # Main colour 4.
    base0C = strip_hash colors.colors.color12;  # Main colour 5.
    base0D = strip_hash colors.colors.color13;  # Main colour 6.
    base0E = strip_hash colors.colors.color14;  # Main colour 7.
    base0F = strip_hash colors.colors.color15; # Main colour 8.
  };

  # Read pywal colors if cache exists and scheme is pywal.
  pywal_colors_raw = if builtins.pathExists pywal_cache
    then builtins.readFile pywal_cache
    else null;

  pywal_colors = if pywal_colors_raw != null
    then parse_pywal_colors pywal_colors_raw
    else gruvbox_colors.dark; # Fallback to gruvbox dark.

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

  # Current color scheme (two-dimensional: scheme + light/dark).
  # NOTE: pywal colors are pre-generated in the correct mode (light/dark) by tt command.
  colors = if color_scheme == "pywal"
    then pywal_colors
    else (if is_dark then gruvbox_colors.dark else gruvbox_colors.light);

  variant = if is_dark then "dark" else "light";

  # Convert hex to RGB array helper for colors.
  hexToRgb = hex: let
    r = lib.fromHexString (builtins.substring 0 2 hex);
    g = lib.fromHexString (builtins.substring 2 2 hex);
    b = lib.fromHexString (builtins.substring 4 2 hex);
  in [ r g b ];
in
{
  config.theme = {
    inherit
      # Core theme state.
      is_dark
      color_scheme
      variant
      # Base16 color scheme.
      colors;

    # Color helpers with prefixes.
    withHash = lib.mapAttrs (name: value: "#${value}") colors;
    with0x   = lib.mapAttrs (name: value: "0x${value}") colors;
    withRgb  = lib.mapAttrs (name: value: hexToRgb value) colors;
  };

  # Export theme info as env vars.
  config.environment.variables.THEME_MODE   = variant;
  config.environment.variables.THEME_SCHEME = color_scheme;
}
