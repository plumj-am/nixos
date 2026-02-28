# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "PlumJam's NixOS Configuration Collection";

  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    actions = {
      inputs = {
        flake-parts.follows = "parts";
        nixpkgs.follows = "os";
      };
      url = "github:nialov/actions.nix";
    };
    age = {
      inputs = {
        darwin.follows = "os-darwin";
        nixpkgs.follows = "os";
      };
      url = "github:ryantm/agenix";
    };
    age-rekey = {
      inputs = {
        flake-parts.follows = "parts";
        nixpkgs.follows = "os";
      };
      url = "github:oddlama/agenix-rekey";
    };
    ashell = {
      inputs.nixpkgs.follows = "os";
      url = "github:malpenzibo/ashell";
    };
    determinate = {
      inputs.nixpkgs.follows = "os";
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    };
    disko = {
      inputs.nixpkgs.follows = "os";
      url = "github:nix-community/disko";
    };
    fenix = {
      inputs.nixpkgs.follows = "os";
      url = "github:nix-community/fenix";
    };
    flake-file.url = "github:vic/flake-file";
    ghostty = {
      inputs.nixpkgs.follows = "os";
      url = "github:ghostty-org/ghostty";
    };
    helix = {
      inputs.nixpkgs.follows = "os";
      url = "github:helix-editor/helix";
    };
    hjem = {
      inputs = {
        nix-darwin.follows = "os-darwin";
        nixpkgs.follows = "os";
      };
      url = "github:feel-co/hjem";
    };
    import-tree.url = "github:vic/import-tree";
    niri = {
      inputs.nixpkgs.follows = "os";
      url = "github:niri-wm/niri";
    };
    nix-index = {
      inputs.nixpkgs.follows = "os";
      url = "github:nix-community/nix-index-database";
    };
    nu-lint = {
      inputs.nixpkgs.follows = "os";
      url = "git+https://codeberg.org/wvhulle/nu-lint";
    };
    opencode = {
      inputs.nixpkgs.follows = "os";
      url = "github:anomalyco/opencode";
    };
    os.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    os-darwin = {
      inputs.nixpkgs.follows = "os";
      url = "github:nix-darwin/nix-darwin/master";
    };
    os-wsl = {
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "os";
      };
      url = "github:nix-community/NixOS-WSL/main";
    };
    parts = {
      inputs.nixpkgs-lib.follows = "os";
      url = "github:hercules-ci/flake-parts";
    };
    run0-sudo-shim = {
      inputs.nixpkgs.follows = "os";
      url = "github:plumj-am/run0-sudo-shim";
    };
    zed = {
      inputs.nixpkgs.follows = "os";
      url = "github:zed-industries/zed";
    };
  };

}
