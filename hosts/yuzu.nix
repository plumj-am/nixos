{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Yuzu | desktop | x86_64-linux | NixOS
  flake.nixosConfigurations.yuzu = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      default
      desktop

      ai-agents
      games
      # llama-cpp
      # lmstudio
      # ollama

      { hardware.facter.reportPath = ./facter/yuzu.json; }
      {
        config = mkConfig inputs "yuzu" "x86_64-linux" {
          systemInfo = {
            disks.swap.partition = {
              path = "/dev/disk/by-label/swap";
              size = "34G";
            };
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
