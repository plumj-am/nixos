inputs: self: super: let
  inherit (self) attrValues filter getAttrFromPath hasAttrByPath collectNix;

  # collect common modules that should be applied to all systems
  # Note: we shouldn't automatically collect home modules at system level
  modulesCommon = [];

  # collect input modules and overlays from flake inputs
  collectInputs = let
    inputs' = attrValues inputs;
  in path: inputs'
    |> filter (hasAttrByPath path)
    |> map (getAttrFromPath path);

  inputHomeModules   = collectInputs [ "homeModules"   "default" ];
  inputModulesLinux  = collectInputs [ "nixosModules"  "default" ] ++ [
    inputs.home-manager.nixosModules.home-manager 
    inputs.agenix.nixosModules.default
  ];
  inputModulesDarwin = collectInputs [ "darwinModules" "default" ] ++ [
    inputs.home-manager.darwinModules.home-manager
  ];

  inputOverlays = collectInputs [ "overlays" "default" ];
  overlayModule = { nixpkgs.overlays = inputOverlays; };

  # special arguments passed to all modules
  specialArgs = inputs // {
    inherit inputs;
    lib = self;
    keys = import ../keys.nix;
  };
in {
  # wrapper for nixosSystem that automatically applies common modules
  nixosSystem' = config: super.nixosSystem {
    inherit (config) system;
    inherit specialArgs;

    modules = config.modules ++ [
      overlayModule

      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules = inputHomeModules;
          users.james = import ../home/default.nix {
            inherit (config) system;
            lib = self;
            inherit (inputs) fenix nvf bacon-ls fff-nvim agenix;
            pkgs = import inputs.nixpkgs {
              inherit (config) system;
              config.allowUnfree = true;
              config.permittedInsecurePackages = [
                "arc-browser-1.106.0-66192"
              ];
            };
          };
        };
      }
    ] ++ modulesCommon
      ++ inputModulesLinux;
  };

  # wrapper for darwinSystem that automatically applies common modules  
  darwinSystem' = config: super.darwinSystem {
    inherit (config) system;
    inherit specialArgs;

    modules = config.modules ++ [
      overlayModule

      {
        home-manager.sharedModules = inputHomeModules;
      }
    ] ++ modulesCommon
      ++ inputModulesDarwin;
  };
}