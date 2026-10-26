{ self, ... }:
{
  flake.modules.nixos.tern = self.modules.nixos.tern-options;
  flake.modules.nixos.tern-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) bool;
    in
    {
      options.tern.remote.linger = mkOptionOf bool {
        default = false;
        description = ''
          Start jam's systemd user manager at boot, so `tern remote serve`
          answers before anyone logs in. Off, the service starts at the first
          login -- an ssh session counts -- and stops when the last session
          ends.
        '';
      };
    };
}
