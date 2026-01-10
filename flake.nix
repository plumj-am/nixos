{
  description = "PlumJam's NixOS Configuration Collection";

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

  inputs.import-tree = {
    url = "github:vic/import-tree";
  };

  inputs.hjem = {
    follows = "hjem-rum/hjem";
  };

  inputs.hjem-rum = {
    url = "github:snugnug/hjem-rum";

    inputs.nixpkgs.follows = "os";
  };

  inputs.fenix = {
    url = "github:nix-community/fenix";

    inputs.nixpkgs.follows = "os";
  };

  inputs.disko = {
    url = "github:nix-community/disko";

    inputs.nixpkgs.follows = "os";
  };

  inputs.age = {
    url = "github:ryantm/agenix";

    inputs.nixpkgs.follows = "os";
    inputs.darwin.follows = "os-darwin";
    inputs.home-manager.follows = "";
  };

  inputs.age-rekey = {
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

  outputs = inputs: inputs.parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
