{
  self,
  inputs,
  lib,
  ...
}:
let
  inherit (lib.lists) optional singleton;

  mkHjemModule =
    hjemModule:
    { config, ... }:
    {
      imports = singleton hjemModule;

      config.hjem.extraModules =
        optional (config.hjem.extraModule != null) config.hjem.extraModule
        ++ optional (config.hjemModule != null) config.hjemModule;
    };
in
{
  flake.modules.nixos.default = self.modules.nixos.hjem;
  flake.modules.nixos.hjem = mkHjemModule inputs.hjem.nixosModules.default;

  flake.modules.darwin.default = self.modules.nixos.hjem;
  flake.modules.darwin.hjem = mkHjemModule inputs.hjem.darwinModules.default;
}
