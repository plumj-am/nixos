inputs: self: super: let
  inherit (super) mkDefault;
in {
  # Dendritic pattern helpers for building NixOS/Darwin configurations
  # These use modules defined in flake.modules.* (from dendritic-style host definitions)
  # Note: These use hjem, NOT home-manager

  # mkNixos: Looks up module from flake.modules.nixos.${name}
  mkNixos = system: name:
    inputs.os.lib.nixosSystem {
      specialArgs = inputs // {
        inherit inputs;
        lib = self;
        self = inputs.self;
        keys = inputs.self.keys;
      };
      modules = [
        inputs.self.flake.modules.nixos.${name}
        { nixpkgs.hostPlatform = mkDefault system; }
        {
          nixpkgs.overlays =
            let
              hasOverlay = i: i ? overlays && i.overlays ? default && i.overlays.default != { };
            in
            map (i: i.overlays.default) (builtins.filter hasOverlay (builtins.attrValues inputs));
        }
        inputs.home.nixosModules.default
        inputs.agenix.nixosModules.default
        inputs.agenix-rekey.nixosModules.default
      ];
    };

  # mkNixos': Takes module directly (useful when defining module inline)
  mkNixos' = system: name: module:
    inputs.os.lib.nixosSystem {
      specialArgs = inputs // {
        inherit inputs;
        lib = self;
        self = inputs.self;
        keys = inputs.self.keys;
      };
      modules = [
        module
        { nixpkgs.hostPlatform = mkDefault system; }
        {
          nixpkgs.overlays =
            let
              hasOverlay = i: i ? overlays && i.overlays ? default && i.overlays.default != { };
            in
            map (i: i.overlays.default) (builtins.filter hasOverlay (builtins.attrValues inputs));
        }
        inputs.home.nixosModules.default
        inputs.agenix.nixosModules.default
        inputs.agenix-rekey.nixosModules.default
      ];
    };

  mkDarwin = system: name:
    inputs.os-darwin.lib.darwinSystem {
      specialArgs = inputs // {
        inherit inputs;
        lib = self;
        self = inputs.self;
        keys = inputs.self.keys;
      };
      modules = [
        inputs.self.flake.modules.darwin.${name}
        { nixpkgs.hostPlatform = mkDefault system; }
      ];
    };
}
