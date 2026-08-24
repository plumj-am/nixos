{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Blackwell | server | x86_64-linux | NixOS
  flake.nixosConfigurations.blackwell = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      default
      server

      distributed-builder
      {
        config = mkConfig inputs "blackwell" "x86_64-linux" {
          systemInfo = {
            distributedBuilder.speedFactor = 1;

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
