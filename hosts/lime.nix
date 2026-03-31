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
      editor-extra
      jujutsu-extra
      kitty
      nix-settings-extra-darwin
      rust-desktop
      sudo
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
