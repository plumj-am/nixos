{
  config.flake.modules.nixos.quickshell =
    { pkgs, inputs, ... }:
    {
      services.upower.enable = true;

      environment.systemPackages = [
        pkgs.kdePackages.qt5compat

        inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell
        inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.qml-niri
      ];
    };
}
