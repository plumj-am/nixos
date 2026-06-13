{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Pear | WSL | x86_64-linux | NixOS-WSL
  flake.nixosConfigurations.pear = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      desktop-tools
      harmonia
      jujutsu-extra
      # ncro
      sops
      sudo-extra-desktop
      # s3-upload
      wsl
      zellij
      {
        config = mkConfig inputs "pear" "x86_64-linux" {
          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
