{ self, ... }:
{
  flake.commonModules.env = self.commonModules.env-options;
  flake.commonModules.env-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
    in
    {
      options.sessionPath = mkOption {
        type = listOf str;
        default = [
          ".local/bin"
          ".cargo/bin"
          ".bun/bin"
        ];
        example = [
          ".local/bin"
          ".cargo/bin"
        ];
        description = ''
          Directories appended to `PATH` in the user session, in the given
          order. This is the Hjem equivalent of home-manager's
          `home.sessionPath`, which Hjem does not provide.

          A relative entry is resolved against the user's home directory, so
          this reads cleanly and works for every configured user. An absolute
          entry is used as-is.

          Hjem's `environment.sessionVariables` can only replace a whole
          variable, and it exports through a POSIX script that does not expand
          `$HOME`. Nushell therefore appends these entries itself, which keeps
          the inherited `PATH` intact instead of replacing it.
        '';
      };
    };
}
