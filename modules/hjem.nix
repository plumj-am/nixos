{ inputs, lib, ... }:
let
  inherit (lib.lists) optional singleton;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule nullOr;

  mkHjemModule =
    hjemModule:
    { config, ... }:
    {
      imports = singleton hjemModule;

      # Before:
      # ```nix
      # {
      #  flake.modules.common.something =
      #    {lib, ...}:
      #    let
      #      inherit (lib.lists) singleton;
      #    in
      #    {
      #      hjem.extraModules = singleton { };
      #    };
      # }
      # ```
      #
      # After:
      # ```nix
      # {
      #   flake.modules.common.something = {
      #     hjem.extraModule = { };
      #   };
      # }
      # ```
      options.hjem.extraModule = mkOption {
        type = nullOr deferredModule;
        default = null;
        description = ''
          Single module to be evaluated as a part of the users module
          inside `config.hjem.users.<username>`. Use this instead of
          `extraModules` when you only have one module to add.
        '';
      };

      options.hjemModule = mkOption {
        type = nullOr deferredModule;
        default = null;
        description = ''
          Single module to be evaluated as a part of the users module
          inside `config.hjem.users.<username>`. Use this instead of
          `extraModules` when you only have one module to add.
        '';
      };

      config.hjem.extraModules =
        optional (config.hjem.extraModule != null) config.hjem.extraModule
        ++ optional (config.hjemModule != null) config.hjemModule;
    };
in
{
  flake.modules.nixos.hjem = mkHjemModule inputs.hjem.nixosModules.default;
  flake.modules.darwin.hjem = mkHjemModule inputs.hjem.darwinModules.default;
}
