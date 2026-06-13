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
      # buildbot-worker
      disks-server
      forgejo-action-runner
      harmonia
      # ncro
      nix-settings-extra-server
      radicle-node
      rust
      sops
      sudo-extra-server
      swapfile
      s3-upload
      zellij
      {
        config = mkConfig inputs "blackwell" "x86_64-linux" {
          systemInfo = {
            cores = 2;
            distributedBuilder = {
              enable = false;
              speedFactor = 1;
            };

            disks.swap.file = {
              path = "/swapfile";
              size = 1024 * 2;
            };
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
