{ lib, ... }:
let
  inherit (lib.lists) singleton;
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
