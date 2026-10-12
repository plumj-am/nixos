{ inputs, ... }:
{
  flake.modules.nixos.default = inputs.determinate.nixosModules.default;

  flake.modules.darwin.default = inputs.determinate.darwinModules.default;
}
