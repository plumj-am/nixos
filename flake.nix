{
  description = "PlumJam's NixOS Configuration Collection";

  nixConfig = {
    extra-substituters = [
      "https://cache.plumj.am/"
      "https://cache.garnix.io/"
      "https://numtide.cachix.org/"
      "https://nix-community.cachix.org/"
    ];

    extra-trusted-public-keys = [
      "cache.plumj.am:NnfLDMdPEH3LE5WqFAilb4/UoIUfb0lZoFv2MoeMBbA="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy2Yk6H6WdHjLQ0Rb5h9R0OXiEiL8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    experimental-features = [
      "cgroups"
      "flakes"
      "nix-command"
      "pipe-operators"
    ];

    builders-use-substitutes = true;
    flake-registry           = "";
    http-connections         = 0;
    max-jobs                 = "auto";
    use-cgroups              = true;
    show-trace               = true;
    trusted-users            = [ "root" "@wheel" "build" ];
    warn-dirty               = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixos-wsl = {
      url                    = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url                    = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url                    = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url                    = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bacon-ls = {
      url                    = "github:crisidev/bacon-ls";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url                         = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows      = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    disko = {
      url                    = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url                    = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    github2forgejo = {
      url                    = "github:RGBCube/GitHub2Forgejo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url                    = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, nix-darwin,  ... }: let
    inherit (builtins) readDir;
    inherit (nixpkgs.lib) attrsToList const extend groupBy listToAttrs mapAttrs nameValuePair;

    # Extend nixpkgs.lib with nix-darwin.lib, then our custom lib.
    lib' = nixpkgs.lib.extend (const <| const <| nix-darwin.lib);
    lib  = lib'.extend <| import ./lib inputs;

    rawHosts = readDir ./hosts
      |> mapAttrs (name: const <| import ./hosts/${name} lib);

    hostsByType = rawHosts
      |> attrsToList
      |> groupBy ({ value, ... }:
        if value ? class && value.class == "nixos" then
          "nixosConfigurations"
        else
          "darwinConfigurations")
      |> mapAttrs (const (hosts:
          hosts
          |> map ({ name, value }: nameValuePair name value.config)
          |> listToAttrs));

  in hostsByType // {
    inherit inputs lib;

  };
}
