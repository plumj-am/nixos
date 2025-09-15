{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in {
  home-manager.sharedModules = [{
    programs.alacritty = mkIf config.isDesktopNotWsl (enabled {
      theme    = config.theme.alacritty;
      package  = pkgs.alacritty;
      settings = {
        window.decorations = "None";

        font.size                = 18;
  			font.normal.family       = "IosevkaTerm Nerd Font Mono";

        terminal.shell.program = "/etc/profiles/per-user/james/bin/nu";
      };
    });
  }];
}
