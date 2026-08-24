{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Plum | server | x86_64-linux | NixOS
  flake.nixosConfigurations.plum = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      default
      server

      acme
      cinny
      distributed-builder
      forgejo
      freshrss-server
      gerrit
      goatcounter
      matrix
      nginx
      opengist
      postgres
      radicle-explorer
      uptime-kuma
      users-extra
      website-personal
      { hardware.facter.reportPath = ./facter/plum.json; }
      { disko.devices.disk.disk1.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_102788287"; }
      {
        config = mkConfig inputs "plum" "x86_64-linux" {
          networking.domain = "plumj.am";

          systemInfo = {
            distributedBuilder.speedFactor = 3;

            disks.swap.file = {
              path = "/swapfile";
              size = 1024 * 8;
            };
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
