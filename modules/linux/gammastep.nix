{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.gammastep
  ];

  services.geoclue2.enable = true;

  home-manager.sharedModules = [{
    services.gammastep = enabled {
      temperature.day   = 4500;
      temperature.night = 3500;

      tray     = true;
      provider = "geoclue2";
    };
  }];
}
