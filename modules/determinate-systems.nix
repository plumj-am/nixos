let
  linuxModule =
    { inputs, ... }:
    {
      imports = [ inputs.determinate.nixosModules.default ];
    };

  darwinModule =
    { inputs, ... }:
    {
      imports = [ inputs.determinate.darwinModules.default ];
    };
in
{
  flake-file.inputs = {
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

      inputs.nixpkgs.follows = "os";
    };
  };

  flake.modules.nixos.determinate-systems = linuxModule;
  flake.modules.darwin.determinate-systems = darwinModule;
}
