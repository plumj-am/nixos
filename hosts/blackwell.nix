{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Blackwell | server | x86_64-linux | NixOS
  flake.nixosConfigurations.blackwell = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      boot-grub
      buildbot-worker
      disks-server
      forgejo-action-runner
      harmonia
      # nix-distributed-builder
      nix-distributed-builds
      nix-settings-extra-server
      object-storage
      radicle-node
      rust
      sudo-extra-server
      zellij
      {
        config = mkConfig inputs "blackwell" "x86_64-linux" {
          systemSpecs = {
            cores = 2;
            speedFactor = 1;
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSi4SKhqze7ZzhJFcUF9KW/4nXX1MfvZjUqrYWNDi9c root@blackwell";

          age.secrets = {
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            acmeEnvironment.rekeyFile = ../secrets/acme-environment.age;
            nixStoreKey.rekeyFile = ../secrets/blackwell-nix-store-key.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
