{ self, lib, ... }:
let
  inherit (lib.lists) singleton;
in
{
  # Pear | WSL | x86_64-linux | NixOS-WSL
  imports =
    singleton
    <| lib.systems.nixosSystem "pear" {
      imports = with self.modules.nixos; [
        sops
        sudo-desktop
        wsl
        zellij
      ];

      sops.secrets = {
        password = {
          sopsFile = ../secrets/pear/password.yaml;
          neededForUsers = true;
        };
        id.sopsFile = ../secrets/pear/id.yaml;

        nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = "pear";
        };
      };

      # hardware.facter.reportPath = ./facter/pear.json;
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";
    };
}
