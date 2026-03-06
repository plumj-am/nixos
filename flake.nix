{
  description = "PlumJam's NixOS Configuration Collection";

  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    actions = {
      url = "github:nialov/actions.nix";
      inputs = {
        flake-parts.follows = "parts";
        nixpkgs.follows = "os";
      };
    };
    age = {
      url = "github:ryantm/agenix";
      inputs = {
        darwin.follows = "os-darwin";
        nixpkgs.follows = "os";
      };
    };
    age-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs = {
        flake-parts.follows = "parts";
        nixpkgs.follows = "os";
      };
    };
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "os";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "os";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "os";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs = {
        nix-darwin.follows = "os-darwin";
        nixpkgs.follows = "os";
      };
    };
    niri = {
      url = "github:niri-wm/niri";
      inputs.nixpkgs.follows = "os";
    };
    nix-index = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "os";
    };
    nu-lint = {
      url = "git+https://codeberg.org/wvhulle/nu-lint";
      inputs.nixpkgs.follows = "os";
    };
    os.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    os-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "os";
    };
    os-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "os";
      };
    };
    parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "os";
    };
    # qml-niri = {
    #   url = "github:imiric/qml-niri/main";
    #   inputs = {
    #     nixpkgs.follows = "os";
    #     quickshell.follows = "quickshell";
    #   };
    # };
    # quickshell = {
    #   url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    #   inputs.nixpkgs.follows = "os";
    # };
    run0-sudo-shim = {
      url = "github:plumj-am/run0-sudo-shim";
      inputs.nixpkgs.follows = "os";
    };
    tangled = {
      url = "git+https://tangled.org/tangled.org/core";
      inputs.nixpkgs.follows = "os";
    };
  };
}
