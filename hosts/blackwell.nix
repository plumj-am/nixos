{
  self,
  lib,
  ...
}:
let
  inherit (lib.lists) singleton;
in
{
  # Blackwell | server | x86_64-linux | NixOS
  imports =
    singleton
    <| lib.systems.nixosSystem "blackwell" {
      imports = with self.modules.nixos; [
        server

        distributed-builder
      ];

      systemInfo = {
        distributedBuilder.speedFactor = 1;

        disks.swap.file = {
          path = "/swapfile";
          size = 1024 * 2;
        };
      };

      sops.secrets = {
        password = {
          sopsFile = ../secrets/blackwell/password.yaml;
          neededForUsers = true;
        };
        id.sopsFile = ../secrets/blackwell/id.yaml;

        nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = "blackwell";
        };
      };

      # hardware.facter.reportPath = ./facter/blackwell.json;
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";
    };
}
