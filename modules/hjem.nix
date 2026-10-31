{ self, ... }:
{
  flake.modules.common.hjem =
    { lib, config, ... }:
    let
      inherit (lib.lists) optional;
    in
    {
      config.hjem.extraModules =
        optional (config.hjem.extraModule != null) config.hjem.extraModule
        ++ optional (config.hjemModule != null) config.hjemModule;

    };

  flake.modules.nixos.default = self.modules.nixos.hjem;
  flake.modules.nixos.hjem = { inputs, ... }: inputs.hjem.nixosModules.default;

  flake.modules.darwin.default = self.modules.darwin.hjem;
  flake.modules.darwin.hjem = { inputs, ... }: inputs.hjem.darwinModules.default;
}
