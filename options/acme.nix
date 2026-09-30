{ self, ... }:
{
  flake.modules.nixos.acme = self.modules.nixos.acme-options;
  flake.modules.nixos.acme-options =
    { lib, ... }:
    let
      inherit (lib.options) mkValue;
    in
    {
      options.security.acme.users = mkValue [ ];
    };
}
