{ config, lib, pkgs, ... }: let
  inherit (lib) disabled mkIf;
in {
  home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    programs.alacritty = disabled {
      settings = {
        window.decorations = "None";

        font.size          = config.theme.font.size.normal;
  			font.normal.family = config.theme.font.mono.family;

        terminal.shell.program = "${pkgs.nushell}/bin/nu";

        colors = with config.theme.withHash; {
          primary.foreground   = base05;
          primary.background   = base00;
          cursor.text          = base05;
          cursor.background    = base00;
          selection.text       = base00;
          selection.background = base05;

          normal.black   = base00;
          normal.red     = base08;
          normal.green   = base0B;
          normal.yellow  = base0A;
          normal.blue    = base0D;
          normal.magenta = base0E;
          normal.cyan    = base0C;
          normal.white   = base07;
        };
      };
    };

    # Desktop entry for Zellij in Fuzzel.
    # xdg.desktopEntries.zellij-alacritty = {
    #   name     = "Zellij Alacritty";
    #   icon     = "Alacritty";
    #   exec     = "alacritty -e ${pkgs.zellij}/bin/zellij";
    #   terminal = false;
    # };
  }];
}
