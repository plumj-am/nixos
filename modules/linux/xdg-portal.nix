{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktopNotWsl {
  xdg.portal = enabled {
    config = {
      common.default = "*";
      # Niri screensharing fixes.
      niri = {
        default = "*";

        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
    };

    extraPortals   = [
      pkgs.xdg-desktop-portal-hyprland

      # Niri screensharing fixes.
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    configPackages = [ pkgs.hyprland ];
  };

  environment.systemPackages = [
    pkgs.xdg-utils
  ];

  environment.sessionVariables = {
    # Hint Electron apps to use Wayland.
    NIXOS_OZONE_WL      = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE    = "wayland";
    XDG_SESSION_DESKTOP = "niri";
  };
}
