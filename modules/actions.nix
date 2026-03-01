{ inputs, lib, ... }:
let
  inherit (builtins) filter;
  inherit (lib.strings) hasSuffix;
  inherit (lib.filesystem) listFilesRecursive;
in
{
  imports = [
    inputs.actions.flakeModules.actions-nix
  ]
  ++ filter (f: hasSuffix ".nix" f) (listFilesRecursive ../ci);
}
