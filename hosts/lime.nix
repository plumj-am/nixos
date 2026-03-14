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
        config = mkConfig inputs "lime" "aarch64-darwin" "desktop" {
          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeG5tRLj+z0LlAhH60rQuvRarHWuYE+fYMEgPvGbMrW jam@lime";

          age.secrets = {
            id.rekeyFile = ../secrets/lime-id.age;
            s3AccessKey.rekeyFile = ../secrets/s3-access-key.age;
            s3SecretKey.rekeyFile = ../secrets/s3-secret-key.age;
            context7Key = {
              rekeyFile = ../secrets/context7-key.age;
              owner = "jam";
              mode = "400";
            };
            zaiKey = {
              rekeyFile = ../secrets/z-ai-key.age;
              owner = "jam";
              mode = "400";
            };
          };

          system.stateVersion = 6;
        };
      }
    ];
  };
}
