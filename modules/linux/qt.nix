{ config, lib, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktop {
  home-manager.sharedModules = [{
    qt = enabled {
      platformTheme.name = config.theme.qt.platformTheme;
      style.name         = config.theme.qt.name;
    };
  }];
}