{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Lime | Macbook | x86_64-linux | nix-darwin
  flake.darwinConfigurations.lime = inputs.os-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.darwin; [
      aspectsBase

      app-launcher
      claude-code
      editor-extra
      jujutsu-extra
      kitty
      nix-settings-extra-darwin
      opencode
      peripherals
      radicle
      sops
      # radicle-node
      rust-desktop
      sudo
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
