{ config, pkgs, lib, ...}: let
  inherit (lib) mkIf;
in {
  environment.systemPackages = lib.optionals config.isDesktop [
    pkgs.mprocs
  ];

  home-manager.sharedModules = [{
    home.file.".config/mprocs/mprocs.yaml" = mkIf config.isDesktop {
      text = /* yaml */ ''
        hide_keymap_window: true
        proc_list_width: 15
      '';
    };
  }];
}
