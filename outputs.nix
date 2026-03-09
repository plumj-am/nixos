inputs:
let
  importTree =
    path:
    { lib, ... }:
    let
      inherit (lib) filter;
      inherit (lib.strings) hasSuffix hasInfix;
      inherit (lib.filesystem) listFilesRecursive;
    in
    {
      imports =
        filter (f: hasSuffix ".nix" (toString f) && !hasInfix "/_" (toString f)) <| listFilesRecursive path;
    };
in
inputs.parts.lib.mkFlake { inherit inputs; } {
  imports = [
    (importTree ./modules)
    (importTree ./hosts)
  ];
}
