{ inputs, lib, ... }:
let
  inherit (lib.lists) singleton;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule nullOr;
  inherit (lib.modules) mkIf;

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

      config.hjem.extraModules = mkIf (config.hjem.extraModule != null) [
        config.hjem.extraModule
      ];
    };
in
{
  flake.modules.nixos.hjem = mkHjemModule inputs.hjem.nixosModules.default;
  flake.modules.darwin.hjem = mkHjemModule inputs.hjem.darwinModules.default;
}
