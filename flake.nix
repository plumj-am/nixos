{
  description = "jamesukiyo's NixOS WSL Configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org/"
      "https://cache.nixos.org/"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    experimental-features = [
      # "cgroups"
      "flakes"
      "nix-command"
      "pipe-operators"
    ];

    builders-use-substitutes = true;
    flake-registry           = "";
    http-connections         = 50;
    lazy-trees               = true;
    show-trace               = true;
    trusted-users            = [ "root" "@wheel" "james" ];
    # use-cgroups              = true;
    warn-dirty               = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
    
    bacon-ls.url = "github:crisidev/bacon-ls";
    bacon-ls.inputs.nixpkgs.follows = "nixpkgs";

    fff-nvim.url = "github:dmtrKovalenko/fff.nvim";
    fff-nvim.inputs.nixpkgs.follows = "nixpkgs";

		disko.url = "github:nix-community/disko";
		disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { nixpkgs, nixos-wsl, nix-darwin, home-manager, fenix, nvf, bacon-ls, fff-nvim, disko, ... }: let
    inherit (nixpkgs.lib) const extend;

    # extend nixpkgs.lib with nix-darwin.lib, then our custom lib
    lib' = nixpkgs.lib.extend (const <| const <| nix-darwin.lib);
    lib  = lib'.extend <| import ./lib inputs;

    systems = {
      linux = "x86_64-linux";
      darwin = "aarch64-darwin";
    };

      mkHomeConfig = system: {
        inherit
          system
          lib
          fenix
          nvf
          bacon-ls
          fff-nvim
          ;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.permittedInsecurePackages = [
            "arc-browser-1.106.0-66192"
          ];
        };
      };
  in {
    inherit inputs lib;

    nixosConfigurations."nixos-wsl" = lib.nixosSystem' {
      system = systems.linux;
      modules = [
        nixos-wsl.nixosModules.wsl
        ./hosts/nixos/configuration.nix
        home-manager.nixosModules.home-manager
        (
          { pkgs, ... }:
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.james = import ./home/default.nix (mkHomeConfig systems.linux);
          }
        )
      ];
    };

    darwinConfigurations.darwin = lib.darwinSystem' {
      system = systems.darwin;
      modules = [
        ./hosts/darwin/configuration.nix
        home-manager.darwinModules.home-manager
        (
          { pkgs, ... }:
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.james = import ./home/default.nix (mkHomeConfig systems.darwin);
          }
        )
      ];
    };
		nixosConfigurations."plum" = lib.nixosSystem' {
      system = systems.linux;
      modules = [
				disko.nixosModules.disko
        ./hosts/plum/configuration.nix
        home-manager.nixosModules.home-manager
        (
          { pkgs, ... }:
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.james = import ./home/default.nix (mkHomeConfig systems.linux);
          }
        )
      ];
		};
  };
}
