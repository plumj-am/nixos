{ lib, config, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {
  home-manager.sharedModules = [{

   services.hyprpaper = enabled {
      settings = {
        preload   = [ "${config.theme.wallpaper}" ];
        wallpaper = [ ",${config.theme.wallpaper}" ];
      };
    };
  }];
}
