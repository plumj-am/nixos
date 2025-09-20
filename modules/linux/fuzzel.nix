{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;
in mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.fuzzel
  ];

  home-manager.sharedModules = [{
    programs.fuzzel.enable = true;
  }];
}