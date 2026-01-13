{
  flake-file.inputs = {
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      inputs.nixpkgs.follows = "os";
    };

    qml-niri = {
      url = "github:imiric/qml-niri/main";

      inputs.nixpkgs.follows = "os";
      inputs.quickshell.follows = "quickshell";
    };
  };

  flake.modules.nixos.quickshell =
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
