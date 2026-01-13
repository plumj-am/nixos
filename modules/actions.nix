{ inputs, lib, ... }:
{
  flake-file.inputs.actions = {
    url = "github:nialov/actions.nix";

    inputs.nixpkgs.follows = "os";
    inputs.flake-parts.follows = "parts";
  };

  imports = [
    inputs.actions.flakeModules.actions-nix
  ]
  ++ lib.filter (path: lib.hasSuffix ".nix" path) (lib.filesystem.listFilesRecursive ../ci);
}
