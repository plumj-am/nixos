{ self, lib, ... }:
let
  inherit (lib.lists) singleton;
in
{
  # Plum | server | x86_64-linux | NixOS
  imports =
    singleton
    <| lib.systems.nixosSystem "plum" {
      imports = with self.modules.nixos; [
        server
        web-server

        cinny
        distributed-builder
        forgejo
        freshrss-server
        gerrit
        goatcounter
        matrix
        opengist
        postgres
        radicle-explorer
        uptime-kuma
        users-extra
        website-personal
      ];

      networking.domain = "plumj.am";

      systemInfo = {
        distributedBuilder.speedFactor = 3;

        disks.swap.file = {
          path = "/swapfile";
          size = 1024 * 8;
        };
      };
      disko.devices.disk.disk1.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_102788287";

      sops.secrets = {
        password = {
          sopsFile = ../secrets/plum/password.yaml;
          neededForUsers = true;
        };
        id.sopsFile = ../secrets/plum/id.yaml;

        nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = "plum";
        };
      };

      hardware.facter.reportPath = ./facter/plum.json;
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";
    };
}
