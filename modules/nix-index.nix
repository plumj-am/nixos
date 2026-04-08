{
  flake.modules.nixos.nix-index =
    { inputs, ... }:
    {
      imports = [ inputs.nix-index.nixosModules.nix-index ];

      programs.nix-index-database.comma.enable = true;
    };

  flake.modules.darwin.nix-index =
    { inputs, ... }:
    {
      imports = [ inputs.nix-index.darwinModules.nix-index ];

      programs.nix-index-database.comma.enable = true;
    };
}
