{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktopNotWsl {
  xdg.portal = enabled {
    config = {
      common.default = "*";
      # [1/2] Niri screensharing fixes.
      niri.default = "*";
      niri."org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
    };

    extraPortals = [
      # pkgs.xdg-desktop-portal-hyprland

      # [2/2] Niri screensharing fixes.
      pkgs.xdg-desktop-portal-gnome
    ];
    # configPackages = [ pkgs.hyprland ];
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
