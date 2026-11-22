{ self, ... }:
{
  flake.nixosModules.tern = self.nixosModules.tern-options;
  flake.nixosModules.tern-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) bool;
    in
    {
      options.tern.installed = mkOption {
        type = bool;
        default = false;
        internal = true;
        description = ''
          Whether this host includes the Tern module. The module sets it
          itself; every host that has it reads the flag from the other hosts to
          build the `tern remote` host list.
        '';
      };

      options.tern.remote.linger = mkOption {
        type = bool;
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
