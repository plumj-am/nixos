{ self, lib, ... }:
let
  inherit (lib.lists) singleton;
in
{
  # Date | laptop/server | x86_64-linux | NixOS
  imports =
    singleton
    <| lib.systems.nixosSystem "date" {
      imports = with self.modules.nixos; [
        desktop

        ai-agents
        brave
        distributed-builder
        forgejo-runner
      ];

      systemInfo = {
        distributedBuilder.speedFactor = 4;

        disks.swap.partition = {
          path = "/dev/disk/by-label/swap";
          size = "18G";
        };
      };

      sops.secrets = {
        password = {
          sopsFile = ../secrets/date/password.yaml;
          neededForUsers = true;
        };
        id.sopsFile = ../secrets/date/id.yaml;

        nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = "date";
        };
      };

      # Used as a server when not used as a laptop.
      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        IdleAction = "ignore";
      };

      hardware.facter.reportPath = ./facter/date.json;
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";
    };
}
