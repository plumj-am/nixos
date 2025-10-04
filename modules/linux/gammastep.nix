{ config, lib, ... }: let
  inherit (lib) mkIf disabled;
in mkIf config.isDesktop {

  services.geoclue2 = disabled {
    appConfig.gammastep = {
      isAllowed = true;
      isSystem  = false;
    };
  };

  home-manager.sharedModules = [{
    services.gammastep = disabled {
      temperature.day   = 4500;
      temperature.night = 3500;

      tray     = true;
      provider = "geoclue2";
    };
  }];
}
