inputs:
let
  importTree =
    path:
    { lib, ... }:
    let
      inherit (builtins) filter;
      inherit (lib.strings) hasSuffix hasInfix;
      inherit (lib.filesystem) listFilesRecursive;
    in
    {
      imports = filter (f: hasSuffix ".nix" f && !hasInfix "/_" f) (listFilesRecursive path);
    };
in
inputs.parts.lib.mkFlake { inherit inputs; } {
  imports = [
    ./modules/flake-inputs.nix
    (importTree ./modules)
  ];
}
