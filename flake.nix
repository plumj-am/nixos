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
        home-manager.follows = "";
        nixpkgs.follows = "os";
        systems.follows = "";
      };
      url = "github:ryantm/agenix";
    };
    age-rekey = {
      inputs = {
        flake-parts.follows = "parts";
        nixpkgs.follows = "os";
        treefmt-nix.follows = "treefmt";
      };
      url = "github:oddlama/agenix-rekey";
    };
    claude-code = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "os";
      };
      url = "github:sadjow/claude-code-nix";
    };
    crane.url = "github:ipetkov/crane";
    disko = {
      inputs.nixpkgs.follows = "os";
      url = "github:nix-community/disko";
    };
    fenix = {
      inputs.nixpkgs.follows = "os";
      url = "github:nix-community/fenix";
    };
    flake-file.url = "github:vic/flake-file";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      inputs.nixpkgs.follows = "os";
      url = "github:hercules-ci/gitignore.nix";
    };
    helix = {
      inputs = {
        nixpkgs.follows = "os";
        rust-overlay.follows = "rust-overlay";
      };
      url = "github:helix-editor/helix";
    };
    hjem = {
      follows = "hjem-rum/hjem";
      inputs = {
        nix-darwin.follows = "os-darwin";
        nixpkgs.follows = "os";
      };
    };
    hjem-rum = {
      inputs = {
        ndg.follows = "";
        nixpkgs.follows = "os";
        treefmt-nix.follows = "";
      };
      url = "github:snugnug/hjem-rum";
    };
    import-tree.url = "github:vic/import-tree";
    niri = {
      inputs = {
        niri-stable.follows = "";
        nixpkgs.follows = "os";
        nixpkgs-stable.follows = "";
        xwayland-satellite-stable.follows = "";
        xwayland-satellite-unstable.follows = "";
      };
      url = "github:sodiboo/niri-flake";
    };
    nix-auto-follow = {
      inputs.nixpkgs.follows = "os";
      url = "github:fzakaria/nix-auto-follow";
    };
    nu-lint = {
      inputs = {
        crane.follows = "crane";
        flake-utils.follows = "flake-utils";
        git-hooks.follows = "";
        nixpkgs.follows = "os";
        rust-overlay.follows = "rust-overlay";
      };
      url = "git+https://codeberg.org/wvhulle/nu-lint";
    };
    nufmt = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "os";
        rust-overlay.follows = "rust-overlay";
        treefmt-nix.follows = "treefmt";
      };
      url = "github:nushell/nufmt";
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
    qml-niri = {
      inputs = {
        nixpkgs.follows = "os";
        quickshell.follows = "quickshell";
      };
      url = "github:imiric/qml-niri/main";
    };
    quickshell = {
      inputs.nixpkgs.follows = "os";
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    };
    rio = {
      inputs = {
        flake-parts.follows = "parts";
        nixpkgs.follows = "os";
        rust-overlay.follows = "";
        systems.follows = "";
      };
      url = "github:raphamorim/rio/main";
    };
    rust-overlay = {
      inputs.nixpkgs.follows = "os";
      url = "github:oxalica/rust-overlay";
    };
    treefmt = {
      inputs.nixpkgs.follows = "os";
      url = "github:numtide/treefmt-nix";
    };
  };

}
