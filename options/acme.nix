{ self, ... }:
{
  flake.nixosModules.acme = self.nixosModules.acme-options;
  flake.nixosModules.acme-options =
    { lib, ... }:
    let
      inherit (lib.options) mkValue;
    in
    {
      options.security.acme.users = mkValue [ ];
    };
}
