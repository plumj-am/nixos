{
  lib,
  config,
  moduleLocation,
  ...
}:
let
  inherit (lib.lists) singleton;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.options) mkOption;
  inherit (lib.types) lazyAttrsOf deferredModule;
  inherit (lib.strings) escapeNixIdentifier;

  # Extended version of flake-parts' addInfo that treats "common" like "generic"
  # (classless), so common modules can be imported into any module class.
  addInfo =
    class: moduleName:
    if class == "generic" || class == "common" then
      module: module
    else
      module:
      { ... }:
      {
        _class = class;
        _file = "${toString moduleLocation}#modules.${escapeNixIdentifier class}.${escapeNixIdentifier moduleName}";
        imports = singleton module;
      };
in
{
  imports =
    singleton
      # NOTE: We do NOT import inputs.parts.flakeModules.modules.
      # We define flake.modules ourselves with support for a classless "common"
      # namespace, plus auto-merge into nixos and darwin.
      {
        perSystem =
          { inputs', ... }:
          {
            _module.args.pkgs = inputs'.nixpkgs.legacyPackages;
          };
      };

  # systems = [
  #   "x86_64-linux"
  #   "aarch64-darwin"
  # ];

  options.flake.modules = mkOption {
    type = lazyAttrsOf <| lazyAttrsOf deferredModule;

    apply = mapAttrs (k: mapAttrs (addInfo k));

    description = ''
      Groups of modules published by the flake.

      The outer attributes declare the class of the modules within it.
      The special attributes "generic" and "common" do not declare a class,
      allowing their modules to be used in any module class.
      "common" modules are automatically merged into "nixos" and "darwin".
    '';
  };

  # Auto-merge common modules into both namespaces.
  config.flake.modules.nixos = config.flake.modules.common or { };
  config.flake.modules.darwin = config.flake.modules.common or { };
}
