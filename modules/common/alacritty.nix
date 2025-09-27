{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in {
  home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    programs.alacritty = enabled {
      theme    = config.theme.alacritty;
      settings = {
        window.decorations = "None";

        font.size          = config.theme.font.size.normal;
  			font.normal.family = config.theme.font.mono.family;

        terminal.shell.program = "${pkgs.nushell}/bin/nu";
      };
    };

    # Desktop entry for Zellij in Fuzzel.
    xdg.desktopEntries.zellij-alacritty = {
      name     = "Zellij Alacritty";
      icon     = "Alacritty";
      exec     = "alacritty -e ${pkgs.zellij}/bin/zellij";
      terminal = false;
    };
  }];
}
