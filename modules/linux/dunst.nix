{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;
in mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.dunst
  ];

  home-manager.sharedModules = [{
    services.dunst.enable = true;
  }];
}