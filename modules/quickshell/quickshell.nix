{
  flake.modules.nixos.quickshell =
    { inputs, pkgs, ... }:
    {
      services.upower.enable = true;

      environment.systemPackages = [
        pkgs.quickshell
        inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.qml-niri

        # Extra packages.
        pkgs.kdePackages.qt5compat

        # Notifications.
        pkgs.libnotify

        # Clipboard.
        pkgs.wl-clipboard
        # Screen brightness.
        pkgs.brightnessctl
        pkgs.bluez
        pkgs.bluez-tools
      ];
    };
}
