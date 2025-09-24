{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in {
  home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    programs.alacritty = enabled {
      theme    = config.theme.alacritty;
      package  = pkgs.alacritty;
      settings = {
        window.decorations = "None";

        font.size          = config.theme.font.size.normal;
  			font.normal.family = config.theme.font.mono.family;

        terminal.shell.program = "${pkgs.nushell}/bin/nu";
      };
    };

    # Desktop entries for Zellij in Fuzzel.
    xdg.desktopEntries.alacritty-zellij = {
      name     = "Zellij";
      icon     = "Alacritty";
      exec     = "alacritty -e ${pkgs.zellij}/bin/zellij";
      terminal = false;
    };
  }];
}
