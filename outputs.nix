inputs:
let
  inherit (inputs.nixpkgs) lib;
  inherit (lib.attrsets)
    filterAttrs
    mapAttrs'
    nameValuePair
    removeAttrs
    ;
  inherit (lib.filesystem) listFilesRecursive readDir;
  inherit (lib.lists) filter;
  inherit (lib.strings) hasInfix hasSuffix removeSuffix;

  importTree = path: {
    imports =
      filter (f: hasSuffix ".nix" (toString f) && !hasInfix "/_" (toString f)) <| listFilesRecursive path;
  };

  readFlakeParts =
    dir:
    readDir dir
    |> filterAttrs (name: _: hasSuffix ".nix" name)
    |> mapAttrs' (name: _: nameValuePair (removeSuffix ".nix" name) "${dir}/${name}");
in
(import "${inputs.flake-parts}/lib.nix" {
  lib = import ./libs inputs.nixpkgs.lib;

  # We never use `debug` or any other extras.
  builtinModules = removeAttrs (readFlakeParts "${inputs.flake-parts}/modules") [ "debug" ];
  extraModules = { };
}).mkFlake
  { inherit inputs; }
  {
    systems = [
      "x86_64-linux"
      "aarch64-darwin"
    ];

    imports = [
      (importTree ./hosts)
      (importTree ./options)
      (importTree ./modules)
      (importTree ./packages)
      (importTree ./services)
    ];
  }
