{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in {
  home-manager.sharedModules = [{
    programs.alacritty = mkIf config.isDesktopNotWsl (enabled {
      theme    = config.theme.alacritty;
      package  = pkgs.alacritty;
      settings = {
        window.decorations = "None";

        font.size                = config.theme.font.size.normal;
  			font.normal.family       = config.theme.font.mono.family;

        terminal.shell.program = "/etc/profiles/per-user/jam/bin/zellij";
        terminal.shell.args    = [ "attach" "plumjam" "--create" ];
      };
    });
  }];
}
