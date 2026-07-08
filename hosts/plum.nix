{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Plum | server | x86_64-linux | NixOS
  flake.nixosConfigurations.plum = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      acme
      boot-grub
      cinny
      disks-server
      forgejo
      freshrss-server
      forgejo-action-runner
      gerrit
      graft-node
      goatcounter
      harmonia
      matrix
      # ncro
      nginx
      nix-settings-extra-server
      opengist
      postgres
      radicle-explorer
      radicle-node
      renovate
      rust
      sops
      sudo-server
      syncthing
      swapfile
      s3-upload
      uptime-kuma
      users-extra
      website-personal
      zellij
      { hardware.facter.reportPath = ./facter/plum.json; }
      # TODO: Fix properly. Issue caused by using sdX I think.
      # It changes the boot device by itself occasionally.
      { disko.devices.disk.disk1.device = "/dev/sda"; }
      {
        config = mkConfig inputs "plum" "x86_64-linux" {
          networking = {
            domain = "plumj.am";
            firewall.allowedTCPPorts = [
              22
              80
              443
            ];
          };

          systemInfo = {
            cores = 4;
            distributedBuilder = {
              enable = true;
              speedFactor = 3;
            };
            ciRunner.strong = true;

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
