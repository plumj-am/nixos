{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktopNotWsl {
  services.libinput = enabled {
    mouse.leftHanded    = true;
    touchpad.leftHanded = true;
  };
}
