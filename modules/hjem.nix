{ lib, ... }:
let
  inherit (lib.lists) singleton;
  inherit (lib.types) deferredModule nullOr;
in
{
  flake.modules.nixos.hjem =
    { inputs, config, ... }:
    {
      imports = singleton inputs.hjem.nixosModules.default;

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

  flake.modules.darwin.hjem =
    { inputs, config, ... }:
    {
      imports = singleton inputs.hjem.darwinModules.default;

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
}
