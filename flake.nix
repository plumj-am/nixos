{
  description = "PlumJam's NixOS Configuration Collection";

  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    cade = {
      url = "github:manic-systems/cade";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gerrit-autosubmit = {
      url = "git+ssh://forgejo@git.plumj.am/plumjam/gerrit-autosubmit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    grove = {
      url = "git+ssh://forgejo@git.plumj.am/grove-systems/grove";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-webui = {
      url = "github:nesquena/hermes-webui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    jj-mode-el = {
      url = "github:bolivier/jj-mode.el";
      flake = false;
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-core = {
      url = "github:manic-systems/nixos-core";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable-small";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    qml-niri = {
      url = "github:imiric/qml-niri/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    run0-sudo-shim = {
      url = "github:LordGrimmauld/run0-sudo-shim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    steam-config = {
      url = "github:different-name/steam-config-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ublock = {
      flake = false;
      url = "github:imputnet/uBlock";
    };
    zyouz = {
      url = "github:plumj-am/zyouz/tmp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    graft = {
      url = "git+file:///home/jam/projects/grove?ref=graft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xylem = {
      url = "git+file:///home/jam/projects/grove?ref=xylem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
