{ self, lib, ... }:
let
  inherit (lib.lists) singleton;
in
{
  # Yuzu | desktop | x86_64-linux | NixOS
  imports =
    singleton
    <| lib.systems.nixosSystem "yuzu" {
      imports = with self.modules.nixos; [
        desktop

        ai-agents
        games
        # llama-cpp
        # lmstudio
        # ollama
      ];

      systemInfo = {
        disks.swap.partition = {
          path = "/dev/disk/by-label/swap";
          size = "34G";
        };
      };

      sops.secrets = {
        password = {
          sopsFile = ../secrets/yuzu/password.yaml;
          neededForUsers = true;
        };
        id.sopsFile = ../secrets/yuzu/id.yaml;

        nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = "yuzu";
        };
      };

      hardware.facter.reportPath = ./facter/yuzu.json;
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";
    };
}
