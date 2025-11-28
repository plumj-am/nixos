{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(echo -e "Shutdown\nReboot\nSleep\nHibernate\nLock" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "Power: ")

    case "$choice" in
      "Shutdown")
        systemctl poweroff
        ;;
      "Reboot")
        systemctl reboot
        ;;
      "Sleep")
        hyprlock --quiet & systemctl suspend
        ;;
      "Hibernate")
        hyprlock --quiet & systemctl hibernate
        ;;
      "Lock")
        hyprlock --quiet --grace 60
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
