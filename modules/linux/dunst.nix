{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktop {
  home-manager.sharedModules = [{
    services.dunst = enabled;
  }];
}
