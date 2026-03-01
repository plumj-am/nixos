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
  flake.modules.nixos.determinate-systems = linuxModule;
  flake.modules.darwin.determinate-systems = darwinModule;
}
