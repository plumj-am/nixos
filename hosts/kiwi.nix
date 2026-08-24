{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Kiwi | server | x86_64-linux | NixOS
  flake.nixosConfigurations.kiwi = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      default
      server

      acme
      distributed-builder
      nginx
      website-radka
      { hardware.facter.reportPath = ./facter/kiwi.json; }
      {
        config = mkConfig inputs "kiwi" "x86_64-linux" {
          networking.domain = "dr-radka.pl";

          systemInfo = {
            distributedBuilder.speedFactor = 2;

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
