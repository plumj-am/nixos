{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktop {
  home-manager.sharedModules = [{
    services.dunst = with config.theme; enabled {
      settings.global = {
        dmenu = "fuzzel --dmenu";
        monitor = if config.networking.hostName == "yuzu" then 1 else null;

        font = "${font.mono.name}:size=${toString font.size.normal}";
      };
    };
  }];
}
