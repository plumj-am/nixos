let
  commonSpecialArgs = config: inputs: {
    inherit inputs;
    inherit (config.age) secrets;
    inherit (config.network) hostName;

    isDesktop = config.isDesktop or false;
    isServer = config.isServer or false;
    isWsl = config.isWsl or false;
    isLinux = config.isLinux or false;
    isDarwin = config.isDarwin or false;
  };

in
{
  flake-file.inputs = {
    hjem = {
      follows = "hjem-rum/hjem";

      inputs.nixpkgs.follows = "os";
      inputs.nix-darwin.follows = "os-darwin";
    };

    hjem-rum = {
      url = "github:snugnug/hjem-rum";

      inputs.nixpkgs.follows = "os";
      inputs.treefmt-nix.follows = "";
      inputs.ndg.follows = "";
    };
  };

  flake.modules.nixos.hjem =
    {
      lib,
      inputs,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) attrValues;

      hjemModule = inputs.hjem-rum.hjemModules.default;
      hjemModules = attrValues inputs.self.modules.hjem;
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
        {
          hjem.extraModules = [ hjemModule ] ++ hjemModules;

          hjem.specialArgs = commonSpecialArgs config inputs // {
            theme = config.theme;
          };
        }
      ];

    };

  flake.modules.darwin.hjem =
    {
      lib,
      inputs,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) attrValues;

      hjemModule = inputs.hjem-modules.hjemModules.default;
      hjemModules = attrValues inputs.self.modules.hjem;
    in
    {
      imports = [
        inputs.hjem.darwinModules.default
        {
          hjem.extraModules = [ hjemModule ] ++ hjemModules;

          hjem.specialArgs = commonSpecialArgs config inputs;
        }
      ];
    };
}
