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

      ai-extra
      app-launcher
      claude-code
      editor-extra
      jujutsu-extra
      kitty
      nix-settings-extra-darwin
      opencode
      peripherals
      radicle
      # radicle-node
      rust-desktop
      sudo
      theme-extra-fonts
      zed
      zellij
      {
        config = mkConfig inputs "lime" "aarch64-darwin" {
          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeG5tRLj+z0LlAhH60rQuvRarHWuYE+fYMEgPvGbMrW jam@lime";

          system.stateVersion = 6;
        };
      }
    ];
  };
}
