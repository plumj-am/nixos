{ lib, config, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {
  home-manager.sharedModules = [{

    services.hyprsunset = enabled {
      settings = {
        profile = [
          {
            time        = "7:00";
            temperature = 4250;
          }
          {
            time        = "18:15";
            temperature = 3500;
          }
        ];
      };
    };
  }];
}
