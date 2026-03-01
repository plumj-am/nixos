let
  commonModule =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      nix.settings = {
        extra-substituters = singleton "https://install.determinate.systems";
        extra-trusted-public-keys = singleton "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=";
      };
    };

  linuxModule =
    { inputs, ... }:
    {
      imports = [
        commonModule
        inputs.determinate.nixosModules.default
      ];
    };

  darwinModule =
    { inputs, ... }:
    {
      imports = [
        commonModule
        inputs.determinate.darwinModules.default
      ];
    };
in
{
  flake.modules.nixos.determinate-systems = linuxModule;
  flake.modules.darwin.determinate-systems = darwinModule;
}
