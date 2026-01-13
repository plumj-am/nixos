{
  flake.modules.nixos.power-menu =
    { pkgs, ... }:
    let
      powerMenu = pkgs.writeShellScriptBin "power-menu" ''
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
    in
    {
      environment.systemPackages = [
        powerMenu
      ];
    };
}
