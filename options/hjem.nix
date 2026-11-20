{ self, ... }:
{
  flake.modules.common.hjem = self.modules.common.hjem-options;
  flake.modules.common.hjem-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) deferredModule nullOr;
    in
    {
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
    };
}
