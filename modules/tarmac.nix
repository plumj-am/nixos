{ inputs, ... }:
{
  flake.nixosModules.default = inputs.tarmac.nixosModules.default;

  flake.darwinModules.default = inputs.tarmac.darwinModules.default;
}
