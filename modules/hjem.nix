{ lib, ... }:
let
  inherit (lib.lists) singleton;
in
{
  flake.modules.nixos.hjem =
    { inputs, ... }:
    {
      imports = singleton inputs.hjem.nixosModules.default;
    };

  flake.modules.darwin.hjem =
    { inputs, ... }:
    {
      imports = singleton inputs.hjem.darwinModules.default;
    };
}
