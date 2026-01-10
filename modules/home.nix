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
      hjemModule = inputs.hjem-rum.hjemModules.default;
      hjemModules = lib.attrValues inputs.self.modules.hjem;

      themeModule = inputs.self.modules.nixos.theme;
      theme =
        (lib.evalModules {
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
        }).config.theme;
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
        {
          hjem.extraModules = [ hjemModule ] ++ hjemModules;

          hjem.specialArgs = {
            inherit inputs theme;
            inherit (config.age) secrets;
            inherit (config.network) hostName;
            isDesktop = config.isDesktop or false;
            isServer = config.isServer or false;

            isLinux = config.isLinux or false;
            isDarwin = config.isDarwin or false;
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
      hjemModule = inputs.hjem-modules.hjemModules.default;
      hjemModules = lib.attrValues inputs.self.modules.hjem;
    in
    {
      imports = [
        inputs.hjem.darwinModules.default
        {
          hjem.extraModules = [ hjemModule ] ++ hjemModules;

          hjem.specialArgs = {
            isDesktop = config.isDesktop or false;
            isServer = config.isServer or false;

            isLinux = config.isLinux or false;
            isDarwin = config.isDarwin or false;
          };
        }
      ];
    };
}
