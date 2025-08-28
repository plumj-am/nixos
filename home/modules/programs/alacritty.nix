{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.alacritty = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    theme = config.theme.alacritty;
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
        program = "/etc/profiles/per-user/james/bin/nu";
      };
    };
  };
}
