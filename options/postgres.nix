{ self, ... }:
{
  flake.nixosModules.postgres = self.nixosModules.postgres-options;
  flake.nixosModules.postgres-options =
    { lib, ... }:
    let
      inherit (lib.options) mkValue;
    in
    {
      options.services.postgresql.ensure = mkValue [ ];
    };
}
