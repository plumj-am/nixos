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
      url = "github:feel-co/hjem";

      inputs.nixpkgs.follows = "os";
      inputs.nix-darwin.follows = "os-darwin";
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

      hjemModules = inputs.self.modules.hjem |> attrValues;
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
        {
          hjem.extraModules = hjemModules;

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

      hjemModules = inputs.self.modules.hjem |> attrValues;
    in
    {
      imports = [
        inputs.hjem.darwinModules.default
        {
          hjem.extraModules = hjemModules;

          hjem.specialArgs = commonSpecialArgs config inputs // {
            inherit (config) theme;
          };
        }
      ];
    };
}
