{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.gammastep
  ];

  home-manager.sharedModules = [{
    services.gammastep = enabled {
      provider = "geoclue2";
    };
  }];
}
