{ self, ... }:
{
  flake.commonModules.hjem = self.commonModules.hjem-options;
  flake.commonModules.hjem-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) deferredModule nullOr;
    in
    {
      # Before:
      # ```nix
      # {
      #  flake.commonModules.something =
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
      #   flake.commonModules.something = {
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
