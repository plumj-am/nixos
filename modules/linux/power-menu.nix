{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(echo -e "Shutdown\nReboot\nSleep\nLock" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "Power: ")

    case "$choice" in
      "Shutdown")
        systemctl poweroff
        ;;
      "Reboot")
        systemctl reboot
        ;;
      "Sleep")
        swaylock -fF & systemctl suspend
        ;;
      "Lock")
        swaylock -fF
        ;;
      *)
        exit 1
        ;;
    esac
  '';
in mkIf config.isDesktopNotWsl {
  environment.systemPackages = [
    power-menu
  ];
}
