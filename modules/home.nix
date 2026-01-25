let
  commonSpecialArgs = config: inputs: {
    inherit inputs;
    inherit (config.age) secrets;
    inherit (config.network) hostName;
    inherit (config)
      myLib
      isDesktop
      isServer
      isWsl
      isLinux
      isDarwin
      ;
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
      # Perhaps we shouldn't do ^this^ and import the necessary modules per host?
      # This would eliminate the need for a lot of conditional configs.
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
        {
          hjem.extraModules = [ hjemModule ] ++ hjemModules;

          hjem.specialArgs = commonSpecialArgs config inputs // {
            inherit (config) theme;
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
      # Perhaps we shouldn't do ^this^ and import the necessary modules per host?
      # This would eliminate the need for a lot of conditional configs.
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
