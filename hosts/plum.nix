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
      buildbot-master
      buildbot-worker
      cinny
      # circus-agent
      # circus-server
      # circus-queue-runner
      disks-server
      forgejo
      freshrss-server
      forgejo-action-runner
      gerrit
      # gerrit-circus-bridge
      goatcounter
      gradient-worker
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
      sudo-extra-server
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
      { disko.devices.disk.disk1.device = "/dev/sdb"; }
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

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";

          age.secrets = {
            forgejoSigningKey = {
              rekeyFile = ../secrets/plum-forgejo-signing-key.age;
              owner = "forgejo";
            };
            forgejoSigningKeyPub = {
              rekeyFile = ../secrets/plum-forgejo-signing-key-pub.age;
              owner = "forgejo";
            };
            opengistEnvironment = {
              rekeyFile = ../secrets/plum-opengist-environment.age;
              owner = "forgejo";
            };
            rssAdminPassword = {
              rekeyFile = ../secrets/plum-rss-password.age;
              owner = "freshrss";
              mode = "400";
            };
            matrixSigningKey = {
              rekeyFile = ../secrets/plum-matrix-signing-key.age;
              owner = "matrix-synapse";
              group = "matrix-synapse";
            };
            matrixRegistrationSecret = {
              rekeyFile = ../secrets/plum-matrix-registration-secret.age;
              owner = "matrix-synapse";
              group = "matrix-synapse";
            };
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            forgejoAdminPassword.rekeyFile = ../secrets/plum-forgejo-password.age;
            nixStoreKey.rekeyFile = ../secrets/plum-nix-store-key.age;
            resticPassword.rekeyFile = ../secrets/restic-password.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
