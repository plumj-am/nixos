{ inputs, lib, ... }:
let
  inherit (inputs.self) mkConfig;
  inherit (lib.modules) mkForce;
in
{
  # Sloe | server | x86_64-linux | NixOS
  flake.nixosConfigurations.sloe = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      acme
      boot-grub
      disks-server
      forgejo-action-runner
      garage
      graft-node
      graft-sentinel
      graphics
      harmonia
      # ncro
      nextcloud
      nginx
      nix-settings-extra-server
      openssh-extra-users
      radicle-node
      raperl
      rust
      sops
      sudo-server
      syncthing
      swapfile
      s3-upload
      users-extra
      zellij
      { hardware.facter.reportPath = ./facter/sloe.json; }
      # TODO: Fix properly. Issue caused by using sdX I think.
      # It changes the boot device by itself occasionally.
      { disko.devices.disk.disk1.device = "/dev/sda"; }
      {
        config = mkConfig inputs "sloe" "x86_64-linux" {
          networking = {
            domain = "plumj.am";
            firewall.allowedTCPPorts = [
              22
              80
              443
            ];
          };

          systemInfo = {
            cores = 12;
            distributedBuilder = {
              enable = true;
              speedFactor = 5;
            };
            ciRunner.strong = true;

            disks.swap.file = {
              path = "/swapfile";
              size = 1024 * 32;
            };
          };

          # Very large disk, can hold on to things for longer.
          nix.gc = {
            options = mkForce "--delete-older-than 14d";
            dates = mkForce "*-*-01/14 00:00:00"; # Every 2 weeks.
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
