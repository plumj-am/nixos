{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.default
    inputs.flake-file.flakeModules.nix-auto-follow
  ];

  flake-file = {
    description = "PlumJam's NixOS Configuration Collection";

    inputs = {
      flake-file = {
        url = "github:vic/flake-file";
      };

      import-tree = {
        url = "github:vic/import-tree";
      };

      # Fix for `nix-auto-follow.inputs.nixpkgs` trying to follow "nixpkgs".
      nix-auto-follow = {
        url = "github:fzakaria/nix-auto-follow";
        inputs.nixpkgs.follows = "os";
      };

      # Fixes for `nix-auto-follow` warnings:

      # Removes duplicates between `hjem.inputs.smfh` and `helix`.
      rust-overlay = {
        url = "github:oxalica/rust-overlay";
        inputs.nixpkgs.follows = "os";
      };

      # Removes duplicate between `hjem-rum` and `age-rekey`.
      treefmt = {
        url = "github:numtide/treefmt-nix";
      };
    };
  };
}
