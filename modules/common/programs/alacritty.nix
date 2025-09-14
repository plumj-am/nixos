{ config, lib, pkgs, ... }:

{
  home-manager.sharedModules = [{
    programs.alacritty = lib.mkIf pkgs.stdenv.isDarwin {
      enable   = true;
      theme    = config.theme.alacritty;
      package  = pkgs.alacritty;
      settings = {
        window.decorations = "None";

        font.size                = 22;
  			font.builtin_box_drawing = false;
  			font.normal.family       = "IosevkaTerm Nerd Font Mono";
  			font.normal.style        = "Regular";

        cursor.unfocused_hollow = true;

        terminal.shell.program = "/etc/profiles/per-user/james/bin/nu";
      };
    };
  }];
}
