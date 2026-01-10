{ self, inputs, ... }:
{
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

      config.age.rekey = {
        storageMode = "local";
        masterIdentities = [ ../yubikey.pub ];
        localStorageDir = ../secrets/rekeyed/${config.networking.hostName};
      };
    };

  config.flake.modules.darwin.secret-manager = {
    imports = [
      inputs.age.darwinModules.default
    ];
  };
}
