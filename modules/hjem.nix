{ self, ... }:
{
  flake.commonModules.hjem =
    { lib, config, ... }:
    let
      inherit (lib.lists) optional;
    in
    {
      config.hjem.extraModules =
        optional (config.hjem.extraModule != null) config.hjem.extraModule
        ++ optional (config.hjemModule != null) config.hjemModule;

    };

  flake.nixosModules.default = self.nixosModules.hjem;
  flake.nixosModules.hjem = { inputs, ... }: inputs.hjem.nixosModules.default;

  flake.darwinModules.default = self.darwinModules.hjem;
  flake.darwinModules.hjem = { inputs, ... }: inputs.hjem.darwinModules.default;
}
