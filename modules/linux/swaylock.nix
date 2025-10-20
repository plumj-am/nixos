{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {

  security.pam.services.swaylock = enabled {
    u2fAuth = true;
  };

  home-manager.sharedModules = [{
    programs.swaylock = enabled {
      settings = {
        # image                  = "/home/jam/wallpapers/067.png";
        daemonize              = true;
        show-failed-attempts   = true;
        indicator-idle-visible = true;
        font-size              = 16;
        indicator-radius       = 100;
        indicator-thickness    = 10;

        color              = "#000000";
        key-hl-color       = "#e7dd5d";
        separator-color    = "#fefefd";
        inside-color       = "#00000000";
        ring-color         = "#989794";
        text-color         = "#352623";
        ring-ver-color     = "#e7dd5d";
        inside-ver-color   = "#00000000";
        text-ver-color     = "#352623";
        ring-wrong-color   = "#e12d5e";
        inside-wrong-color = "#00000000";
        text-wrong-color   = "#352623";
        bs-hl-color        = "#e12d5e";
      };
    };
  }];

}
