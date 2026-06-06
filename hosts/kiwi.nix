{ inputs, lib, ... }:
let
  inherit (inputs.self) mkConfig;
  inherit (lib.lists) singleton;
in
{
  # Kiwi | server | x86_64-linux | NixOS
  flake.nixosConfigurations.kiwi = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      acme
      boot-grub
      buildbot-worker
      circus-agent
      disks-server
      disks-extra-zram-swap
      forgejo-action-runner
      harmonia
      # ncro
      nginx
      nix-distributed-builder
      nix-distributed-builds
      nix-settings-extra-server
      radicle-node
      rust
      sudo-extra-server
      syncthing
      s3-upload
      website-dr-radka
      zellij
      { hardware.facter.reportPath = ./facter/kiwi.json; }
      {
        config = mkConfig inputs "kiwi" "x86_64-linux" {
          networking = {
            domain = "dr-radka.pl";
            firewall.allowedTCPPorts = [
              22
              80
              443
            ];
          };

          systemSpecs = {
            cores = 2;
            speedFactor = 2;
          };

          swapDevices = singleton {
            device = "/swapfile";
            size = 1024 * 2;
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElcSHxI64xqUUKEY83tKyzEH+fYT5JCWn3qCqtw16af root@kiwi";

          age.secrets = {
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            acmeEnvironment.rekeyFile = ../secrets/acme-environment.age;
            drRadkaEnvironment = {
              rekeyFile = ../secrets/kiwi-dr-radka-environment.age;
              owner = "dr-radka";
              group = "dr-radka";
            };
            nixStoreKey.rekeyFile = ../secrets/kiwi-nix-store-key.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
