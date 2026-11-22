{ self }:
{
  systems.darwinSystem =
    hostName: module:
    { inputs, ... }:
    {
      flake.darwinConfigurations.${hostName} = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };

        lib = self;

        modules = [
          inputs.self.darwinModules.default

          module

          {
            networking.hostName = hostName;
          }
        ];
      };
    };

  systems.nixosSystem =
    hostName: module:
    { inputs, ... }:
    {
      flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        lib = self;

        modules = [
          inputs.self.nixosModules.default

          module

          {
            networking.hostName = hostName;
          }
        ];
      };
    };
}
