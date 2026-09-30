{ self, ... }:
{
  flake.modules.nixos.postgres = self.modules.nixos.postgres-options;
  flake.modules.nixos.postgres-options =
    { lib, ... }:
    let
      inherit (lib.options) mkValue;
    in
    {
      options.services.postgresql.ensure = mkValue [ ];
    };
}
