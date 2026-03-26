{
  flake.modules.nixos.quickshell =
    { inputs, pkgs, ... }:
    {
      services.upower.enable = true;

      environment.systemPackages = [
        inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell
        inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.qml-niri

        # Extra packages.
        pkgs.kdePackages.qt5compat

        # Notifications.
        pkgs.libnotify
      ];
    };
}
