{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Lime | Macbook | x86_64-linux | nix-darwin
  flake.darwinConfigurations.lime = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.darwin; [
      default

      ai-agents
      desktop
      {
        config = mkConfig inputs "lime" "aarch64-darwin" {
          system.stateVersion = 6;
        };
      }
    ];
  };
}
