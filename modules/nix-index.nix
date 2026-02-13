let
  nixIndexBase = {
    programs.nix-index-database.comma.enable = true;
  };

  nixIndexNixos =
    { inputs, ... }:
    {
      imports = [
        nixIndexBase
        inputs.nix-index.nixosModules.nix-index
      ];
    };
  nixIndexDarwin =
    { inputs, ... }:
    {
      imports = [
        nixIndexBase
        inputs.nix-index.darwinModules.nix-index
      ];
    };
in
{
  flake-file.inputs = {
    nix-index = {
      url = "github:nix-community/nix-index-database";

      inputs.nixpkgs.follows = "os";
    };

  };
  flake.modules.nixos.nix-index = nixIndexNixos;
  flake.modules.darwin.nix-index = nixIndexDarwin;
}
