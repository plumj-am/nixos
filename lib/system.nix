inputs: self: super: let
  flakeOutputs = inputs.self;
  inherit (self) attrValues filter getAttrFromPath hasAttrByPath collectNix;

  # collect common modules that should be applied to all systems
  modulesCommon = collectNix (inputs.self + /modules/common);
  modulesLinux  = collectNix (inputs.self + /modules/linux);
  modulesDarwin = collectNix (inputs.self + /modules/darwin);

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
    # inputs.agenix-rekey.nixosModules.default
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
    self = flakeOutputs;
    keys = flakeOutputs.keys;
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
          sharedModules = inputHomeModules ++ [{
            _module.args = {
              pkgs = import inputs.os {
                inherit (config) system;
              };
              inherit (config) system;
              lib = self;
            };
          }];
        };
      }
    ] ++ modulesCommon ++ modulesLinux ++ inputModulesLinux;
  };

  # wrapper for darwinSystem that automatically applies common modules
  darwinSystem' = config: super.darwinSystem {
    inherit (config) system;
    inherit specialArgs;

    modules = config.modules ++ [
      overlayModule

      {
        home-manager.sharedModules = inputHomeModules ++ modulesCommon;
      }
    ] ++ modulesDarwin ++ inputModulesDarwin;
  };
}
