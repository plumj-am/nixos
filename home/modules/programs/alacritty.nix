{
  config,
  lib,
  pkgs,
  ...
}:
let
  dark_theme = "gruber_darker";
  light_theme = "gruvbox_material_medium_light";
in

{
  programs.alacritty = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    theme = light_theme;
    package = pkgs.alacritty;
    settings = {
      window = {
        decorations = "None";
      };

      font = {
        size = 22;
        builtin_box_drawing = false;
        normal = {
          family = "IosevkaTerm Nerd Font Mono";
          style = "Regular";
        };
      };

      cursor = {
        unfocused_hollow = true;
      };

      terminal.shell = {
        program = "nu -e /etc/profiles/per-user/james/bin/zellij attach james --create";
      };
    };
  };
}
