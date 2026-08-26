inputs:
let
  inherit (inputs.nixpkgs.lib.strings) hasSuffix hasInfix removeSuffix;
  inherit (inputs.nixpkgs.lib.filesystem) readDir;
  inherit (inputs.nixpkgs.lib.attrsets) filterAttrs mapAttrs' nameValuePair;
  inherit (inputs.nixpkgs.lib) filter;
  inherit (inputs.nixpkgs.lib.filesystem) listFilesRecursive;

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

  builtinModules = readFlakeParts "${inputs.flake-parts}/modules";
  extraModules = readFlakeParts "${inputs.flake-parts}/extras";
}).mkFlake
  { inherit inputs; }
  {
    systems = [
      "x86_64-linux"
      "aarch64-darwin"
    ];

    imports = [
      (importTree ./hosts)
      (importTree ./modules)
      (importTree ./packages)
      (importTree ./services)
    ];
  }
