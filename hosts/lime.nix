{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Lime | Macbook | x86_64-linux | nix-darwin
  flake.darwinConfigurations.lime = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.darwin; [
      aspectsBase

      app-launcher
      editor-extra
      opencode
      peripherals
      radicle
      sops
      # radicle-node
      rio
      rust-desktop
      sudo-desktop
      theme-extra-fonts
      zellij
      {
        config = mkConfig inputs "lime" "aarch64-darwin" {
          system.stateVersion = 6;
        };
      }
    ];
  };
}
