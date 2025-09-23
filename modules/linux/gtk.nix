{ config, lib, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktop {
  programs.dconf = enabled;

  home-manager.sharedModules = [{
    gtk = enabled {
      font.name = config.theme.font.sans.name;
      font.size = config.theme.font.size.small;

      iconTheme = config.theme.icons;

      theme.name    = config.theme.gtk.name;
      theme.package = config.theme.gtk.package;
    };
  }];
}
