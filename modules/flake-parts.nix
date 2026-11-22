{
  lib,
  config,
  moduleLocation,
  ...
}:
let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) singleton;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule lazyAttrsOf;
in
{
  imports =
    singleton
      # NOTE: We do NOT import inputs.parts.flakeModules.modules.
      # We define the module outputs ourselves so that one flat set of
      # `commonModules` can feed both `nixosModules` and `darwinModules`.
      {
        perSystem =
          { inputs', ... }:
          {
            _module.args.pkgs = inputs'.nixpkgs.legacyPackages;
          };
      };

  options.flake = {
    # `nixosModules` is declared by flake-parts itself
    # (`modules/nixosModules.nix`, loaded via `builtinModules` in outputs.nix),
    # so only the classless `commonModules` set and `darwinModules` need
    # declarations here. flake-parts has no `darwinModules` module.
    darwinModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = { };
      apply = mapAttrs (
        name: module: {
          _class = "darwin";
          _file = "${toString moduleLocation}#darwinModules.${name}";
          imports = singleton module;
        }
      );
      description = ''
        Darwin modules published by the flake.
      '';
    };

    commonModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = { };
      description = ''
        Modules usable in every module class. They are merged into
        "nixosModules" and "darwinModules", and stay readable on their own so
        one module can be aliased from another (e.g. `commonModules.default`).
      '';
    };

    serviceModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = { };
      description = ''
        Services published by the flake.
      '';
    };
  };

  config.flake.nixosModules = config.flake.commonModules or { };
  config.flake.darwinModules = config.flake.commonModules or { };
}
