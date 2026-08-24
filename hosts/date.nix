{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Date | laptop/server | x86_64-linux | NixOS
  flake.nixosConfigurations.date = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      default
      desktop

      ai-agents
      brave
      distributed-builder
      forgejo-runner

      { hardware.facter.reportPath = ./facter/date.json; }
      {
        config = mkConfig inputs "date" "x86_64-linux" {
          systemInfo = {
            distributedBuilder.speedFactor = 4;

            disks.swap.partition = {
              path = "/dev/disk/by-label/swap";
              size = "18G";
            };
          };

          # Used as a server when not used as a laptop.
          services.logind.settings.Login = {
            HandleLidSwitch = "ignore";
            HandleLidSwitchDocked = "ignore";
            HandleLidSwitchExternalPower = "ignore";
            IdleAction = "ignore";
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
