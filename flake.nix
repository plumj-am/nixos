{
  description = "PlumJam's NixOS Configuration Collection";

  nixConfig = {
    extra-substituters = [
      "https://cache1.plumj.am?priority=10"
      "https://cache2.plumj.am?priority=10"
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache1.plumj.am:rFlt5V4tYjsyo3QMRsaoO9VGYISJR+45tT35/6BpKsA="
      "cache2.plumj.am:IoMjbQ43lgHh8gMoEJj/VYK8c3Xbpc/TLRPKAaQSGas="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    experimental-features = [
      "cgroups"
      "flakes"
      "nix-command"
      "pipe-operators"
    ];

    builders-use-substitutes = true;
    flake-registry = "";
    http-connections = 0;
    max-jobs = "auto";
    use-cgroups = true;
    show-trace = true;
    trusted-users = [
      "root"
      "@wheel"
      "build"
      "gitea-runner"
    ];
    warn-dirty = false;
  };

  inputs.os = {
    url = "github:NixOS/nixpkgs/nixos-unstable-small";
  };

  inputs.os-wsl = {
    url = "github:nix-community/NixOS-WSL/main";

    inputs.nixpkgs.follows = "os";
  };

  inputs.os-darwin = {
    url = "github:nix-darwin/nix-darwin/master";

    inputs.nixpkgs.follows = "os";
  };

  inputs.parts = {
    url = "github:hercules-ci/flake-parts";

    inputs.nixpkgs-lib.follows = "os";
  };

  inputs.home-manager = {
    url = "github:nix-community/home-manager/master";

    inputs.nixpkgs.follows = "os";
  };

  inputs.home = {
    url = "github:feel-co/hjem";

    inputs.nixpkgs.follows = "os";
  };

  inputs.home-modules = {
    url = "github:snugnug/hjem-rum";

    inputs.nixpkgs.follows = "os";
    inputs.hjem.follows = "home";
  };

  inputs.fenix = {
    url = "github:nix-community/fenix";

    inputs.nixpkgs.follows = "os";
  };

  inputs.disko = {
    url = "github:nix-community/disko";

    inputs.nixpkgs.follows = "os";
  };

  inputs.agenix = {
    url = "github:ryantm/agenix";

    inputs.nixpkgs.follows = "os";
    inputs.darwin.follows = "os-darwin";
    inputs.home-manager.follows = "home-manager";
  };

  inputs.agenix-rekey = {
    url = "github:oddlama/agenix-rekey";

    inputs.nixpkgs.follows = "os";
  };

  inputs.helix = {
    url = "github:helix-editor/helix";

    inputs.nixpkgs.follows = "os";
  };

  inputs.niri = {
    url = "github:sodiboo/niri-flake";

    inputs.nixpkgs.follows = "os";
  };

  inputs.opencode = {
    url = "github:anomalyco/opencode";

    inputs.nixpkgs.follows = "os";
  };

  inputs.claude-code = {
    url = "github:sadjow/claude-code-nix";

    inputs.nixpkgs.follows = "os";
  };

  inputs.rio = {
    url = "github:raphamorim/rio/main";

    inputs.nixpkgs.follows = "os";
  };

  outputs =
    inputs:
    inputs.parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      let
        inherit (lib.filesystem) listFilesRecursive;
        inherit (lib.lists) filter;
        inherit (lib.strings) hasSuffix;
      in
      {
        imports = filter (hasSuffix ".mod.nix") (listFilesRecursive ./.);
      }
    );
}
