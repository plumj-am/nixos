{
  description = "jamesukiyo's NixOS WSL Configuration";

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
    bacon-ls.url = "github:crisidev/bacon-ls";
    bacon-ls.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-wsl,
      nix-darwin,
      home-manager,
      fenix,
      nvf,
      bacon-ls,
      ...
    }:
    let
      systems = {
        linux = "x86_64-linux";
        darwin = "aarch64-darwin";
      };

      mkHomeConfig = system: {
        inherit
          system
          fenix
          nvf
          bacon-ls
          ;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations."nixos-wsl" = nixpkgs.lib.nixosSystem {
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

      darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
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
    };
}
