{ inputs, lib, ... }:
let
  inherit (lib.lists) singleton;
  inherit (lib.types) deferredModule nullOr;

  mkHjemModule =
    hjemModule:
    { config, ... }:
    {
      imports = singleton hjemModule;

      options.hjem.extraModule = lib.mkOption {
        type = nullOr deferredModule;
        default = null;
        description = ''
          Single module to be evaluated as a part of the users module
          inside `config.hjem.users.<username>`. Use this instead of
          `extraModules` when you only have one module to add.
        '';
      };

      config.hjem.extraModules = lib.mkIf (config.hjem.extraModule != null) [
        config.hjem.extraModule
      ];
    };
in
{
  flake.modules.nixos.hjem = mkHjemModule inputs.hjem.nixosModules.default;
  flake.modules.darwin.hjem = mkHjemModule inputs.hjem.darwinModules.default;
}
