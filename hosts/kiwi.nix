{ self, lib, ... }:
let
  inherit (lib.lists) singleton;
in
{
  # Kiwi | server | x86_64-linux | NixOS
  imports =
    singleton
    <| lib.systems.nixosSystem "kiwi" {
      imports = with self.modules.nixos; [
        server
        web-server

        website-radka
      ];

      networking.domain = "dr-radka.pl";

      systemInfo = {
        disks.swap.file = {
          path = "/swapfile";
          size = 1024 * 2;
        };
      };

      sops.secrets = {
        password = {
          sopsFile = ../secrets/kiwi/password.yaml;
          neededForUsers = true;
        };
        id.sopsFile = ../secrets/kiwi/id.yaml;

        nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = "kiwi";
        };

      };

      hardware.facter.reportPath = ./facter/kiwi.json;
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";
    };
}
