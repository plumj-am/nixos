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
  flake.modules.nixos.nix-index = nixIndexNixos;
  flake.modules.darwin.nix-index = nixIndexDarwin;
}
