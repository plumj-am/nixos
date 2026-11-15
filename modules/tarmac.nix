{ inputs, ... }:
{
  flake.modules.nixos.default = inputs.tarmac.nixosModules.default;

  flake.modules.darwin.default = inputs.tarmac.darwinModules.default;
}
