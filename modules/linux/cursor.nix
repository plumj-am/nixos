{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.bibata-cursors
  ];

  home-manager.sharedModules = [{
    home.pointerCursor = {
      gtk = enabled;
      x11 = enabled;

      package = pkgs.bibata-cursors;
      name    = "Bibata-Modern-Classic";

      size = 22;
    };

    wayland.windowManager.hyprland.settings.env = [
      "XCURSOR_THEME,Bibata-Modern-Classic"
      "XCURSOR_SIZE,22"
    ];
  }];

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE  = "22";
  };
}
