{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Sloe | server | x86_64-linux | NixOS
  flake.nixosConfigurations.sloe = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      boot-grub
      buildbot-worker
      disks-server
      forgejo-action-runner
      graphics
      harmonia
      nix-distributed-builder
      nix-distributed-builds
      nix-settings-extra-server
      object-storage
      openssh-extra-users
      pi
      radicle-node
      rust
      sudo-extra-server
      syncthing
      users-extra
      zellij
      { hardware.facter.reportPath = ./facter/sloe.json; }
      # TODO: Fix properly. Issue caused by using sdX I think.
      # It changes the boot device by itself occasionally.
      { disko.devices.disk.disk1.device = "/dev/sdc"; }
      {
        config = mkConfig inputs "sloe" "x86_64-linux" {

          nix-builder = {
            cores = 12;
            speedFactor = 5;
          };

          forgejo-action-runner = {
            strong = true;
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK42xzC/vWHZC9SiU/8IBBd2pn7mggBYFQ8themKAic/ root@sloe";
          age.secrets = {
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            nixStoreKey.rekeyFile = ../secrets/sloe-nix-store-key.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
