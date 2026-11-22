{ self, lib, ... }:
let
  inherit (lib.lists) singleton;
in
{
  # Lime | Macbook | aarch64-darwin | nix-darwin
  imports =
    singleton
    <| lib.systems.darwinSystem "lime" {
      imports = with self.darwinModules; [
        desktop

        ai-agents
      ];

      sops.secrets = {
        password = {
          sopsFile = ../secrets/lime/password.yaml;
          neededForUsers = true;
        };
        id.sopsFile = ../secrets/lime/id.yaml;

        nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = "lime";
        };
      };

      nixpkgs.hostPlatform = "aarch64-darwin";
      system.stateVersion = 6;
    };
}
