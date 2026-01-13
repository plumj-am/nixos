{ self, inputs, ... }:
{
  config.flake-file.inputs = {
    age = {
      url = "github:ryantm/agenix";

      inputs.nixpkgs.follows = "os";
      inputs.darwin.follows = "os-darwin";
      inputs.home-manager.follows = "";
      inputs.systems.follows = "";
    };

    age-rekey = {
      url = "github:oddlama/agenix-rekey";

      inputs.nixpkgs.follows = "os";
      inputs.flake-parts.follows = "parts";
      inputs.treefmt-nix.follows = "treefmt";
    };
  };

  config.flake.agenix-rekey = inputs.age-rekey.configure {
    userFlake = self;
    inherit (self) nixosConfigurations;
  };

  config.flake.modules.nixos.secret-manager =
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

  config.flake.modules.darwin.secret-manager = {
    imports = [
      inputs.age.darwinModules.default
    ];
  };
}
