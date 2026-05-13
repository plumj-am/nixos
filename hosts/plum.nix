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
      disks-server
      forgejo
      freshrss-server
      forgejo-action-runner
      gerrit
      # git-next
      gitea-mq
      goatcounter
      harmonia
      matrix
      nginx
      nix-distributed-builder
      nix-distributed-builds
      nix-settings-extra-server
      object-storage
      opengist
      postgres
      radicle-explorer
      radicle-node
      renovate
      rust
      sudo-extra-server
      syncthing
      uptime-kuma
      users-extra
      website-personal
      zellij
      { hardware.facter.reportPath = ./facter/plum.json; }
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

          systemSpecs = {
            cores = 4;
            speedFactor = 3;
            runner.strong = true;
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
            acmeEnvironment.rekeyFile = ../secrets/acme-environment.age;
            nixStoreKey.rekeyFile = ../secrets/plum-nix-store-key.age;
            resticPassword.rekeyFile = ../secrets/plum-restic-password.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
