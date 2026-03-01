{ self, inputs, ... }:
{
  flake.agenix-rekey = inputs.age-rekey.configure {
    userFlake = self;
    nixosConfigurations = self.nixosConfigurations // self.darwinConfigurations;
  };

  flake.modules.nixos.secret-manager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = [
        inputs.age.nixosModules.default
        inputs.age-rekey.nixosModules.default
      ];

      config = {
        environment.systemPackages =
          singleton
            inputs.age-rekey.packages.${pkgs.stdenv.hostPlatform.system}.default;

        age = {
          identityPaths = [ "/root/.ssh/id" ];

          rekey = {
            storageMode = "local";
            masterIdentities = [ ../yubikey.pub ];
            localStorageDir = ../secrets/rekeyed/${config.networking.hostName};
          };
        };
      };
    };

  flake.modules.darwin.secret-manager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      # Import the agenix-rekey module without the _class attribute.
      # We need to import it with a wrapper that makes it compatible with darwin.
      agenixRekeyModule = import (inputs.age-rekey + /modules/agenix-rekey.nix) pkgs;
    in
    {
      imports = [
        inputs.age.darwinModules.default
        agenixRekeyModule
      ];

      config = {
        environment.systemPackages =
          singleton
            inputs.age-rekey.packages.${pkgs.stdenv.hostPlatform.system}.default;
        age = {
          identityPaths = [ "/Users/jam/.ssh/id" ];

          rekey = {
            storageMode = "local";
            masterIdentities = [ ../yubikey.pub ];
            localStorageDir = ../secrets/rekeyed/${config.networking.hostName};
          };
        };
      };
    };
}
