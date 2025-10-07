{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {

  services.geoclue2 = enabled {
    appConfig.gammastep = {
      isAllowed = true;
      isSystem  = false;
    };
  };

  home-manager.sharedModules = [{
    services.gammastep = enabled {
      temperature.day   = 4500;
      temperature.night = 3500;

      tray     = true;
      provider = "geoclue2";
    };
  }];
}
