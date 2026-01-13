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
  config.flake.modules.nixos.hjem =
    {
      lib,
      inputs,
      config,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) attrValues;
      inherit (lib.modules) evalModules;

      hjemModule = inputs.hjem-rum.hjemModules.default;
      hjemModules = attrValues inputs.self.modules.hjem;

      themeModule = inputs.self.modules.nixos.theme;
      inherit
        ((evalModules {
          specialArgs = {
            inherit
              lib
              pkgs
              inputs
              config
              ;
          };
          modules = [
            themeModule
            { config.useTheme = true; }
          ];
        }).config
        )
        theme
        ;
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
        {
          hjem.extraModules = [ hjemModule ] ++ hjemModules;

          hjem.specialArgs = commonSpecialArgs config inputs // {
            inherit theme;
          };
        }
      ];

    };

  config.flake.modules.darwin.hjem =
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
