{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.quickshell;
  flake.modules.nixos.quickshell =
    { inputs, pkgs, ... }:
    {
      services.upower.enable = true;

      environment.systemPackages = [
        pkgs.quickshell
        inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.qml-niri

        # Network interface and address queries for the Network service.
        pkgs.iproute2

        # Extra packages.
        pkgs.kdePackages.qt5compat

        # Notifications.
        pkgs.libnotify

        # Screen brightness.
        pkgs.brightnessctl
        pkgs.bluez
        pkgs.bluez-tools
      ];
    };
}
