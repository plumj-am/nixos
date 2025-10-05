{ lib, config, ... }: let
  inherit (lib) mkIf enabled disabled;
in mkIf config.isDesktopNotWsl {
  home-manager.sharedModules = [{

   services.hyprpaper = disabled {
      settings = let
      in {
        preload   = [ "~/wallpapers" ];
        # wallpaper = [ ",{}" ];
      };
    };
  }];
}
