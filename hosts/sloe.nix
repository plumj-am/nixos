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
      disks-disko
      determinate-systems
      forgejo-action-runner
      linux-kernel-latest
      nix-cache-proxy
      nix-distributed-builder
      nix-distributed-builds
      nix-settings-extra-server
      object-storage
      openssh-extra-users
      prometheus-node-exporter
      radicle-node
      rust
      sudo-extra-server
      users-extra
      {
        config = mkConfig inputs "sloe" "x86_64-linux" "server" {
          nix-cache-proxy.publicKey = "cache-proxy-sloe:naaLkMoioaUUujHWdn8QUwnjxlI7XiJEZkGqPRffPPw=";

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
