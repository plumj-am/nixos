{ self, lib, ... }:
let
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkForce;
in
{
  # Sloe | server | x86_64-linux | NixOS
  imports =
    singleton
    <| lib.systems.nixosSystem "sloe" {
      imports = with self.modules.nixos; [
        server
        web-server

        distributed-builder
        forgejo-runner
        garage
        graft
        graphics
        hermes
        nextcloud
        openssh-grove-systems
        tend
        users-grove-systems
      ];
      networking.domain = "plumj.am";

      systemInfo = {
        distributedBuilder.speedFactor = 5;

        disks.swap.file = {
          path = "/swapfile";
          size = 1024 * 32;
        };
      };
      disko.devices.disk.disk1.device = "/dev/disk/by-id/wwn-0x5001b448b89708e0";

      sops.secrets = {
        password = {
          sopsFile = ../secrets/sloe/password.yaml;
          neededForUsers = true;
        };
        id.sopsFile = ../secrets/sloe/id.yaml;

        nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = "sloe";
        };
      };

      # Very large disk, can hold on to things for longer.
      nix.gc = {
        options = mkForce "--delete-older-than 14d";
        dates = mkForce "*-*-01/14 00:00:00"; # Every 2 weeks.
      };

      hardware.facter.reportPath = ./facter/sloe.json;
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";
    };
}
