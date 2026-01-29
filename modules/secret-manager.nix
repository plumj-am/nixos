{ self, inputs, ... }:
{
  flake-file.inputs = {
    age = {
      url = "github:ryantm/agenix";

      inputs.nixpkgs.follows = "os";
      inputs.darwin.follows = "os-darwin";
    };

    age-rekey = {
      url = "github:oddlama/agenix-rekey";

      inputs.nixpkgs.follows = "os";
      inputs.flake-parts.follows = "parts";
    };
  };

  flake.agenix-rekey = inputs.age-rekey.configure {
    userFlake = self;
    nixosConfigurations = self.nixosConfigurations // self.darwinConfigurations;
  };

  flake.modules.nixos.secret-manager =
    { config, ... }:
    {
      imports = [
        inputs.age.nixosModules.default
        inputs.age-rekey.nixosModules.default
      ];

      config.age = {
        identityPaths = [ "/root/.ssh/id" ];

        rekey = {
          storageMode = "local";
          masterIdentities = [ ../yubikey.pub ];
          localStorageDir = ../secrets/rekeyed/${config.networking.hostName};
        };
      };
    };

  flake.modules.darwin.secret-manager =
    { config, pkgs, ... }:
    let
      # Import the agenix-rekey module without the _class attribute.
      # We need to import it with a wrapper that makes it compatible with darwin.
      agenixRekeyModule = import (inputs.age-rekey + /modules/agenix-rekey.nix) pkgs;
    in
    {
      imports = [
        inputs.age.darwinModules.default
        agenixRekeyModule
      ];

      config.age = {
        identityPaths = [ "/Users/jam/.ssh/id" ];

        rekey = {
          storageMode = "local";
          masterIdentities = [ ../yubikey.pub ];
          localStorageDir = ../secrets/rekeyed/${config.networking.hostName};
        };
      };
    };
}
