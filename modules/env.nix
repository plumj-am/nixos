{ self, ... }:
{
  flake.modules.common.default = self.modules.common.env;
  flake.modules.common.env =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter;
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
      # TODO: Make an option.
      variables = {
        EDITOR = "hx";
        SHELL = getExe pkgs.nushell;
        TERMINAL = "herdr";
        TERM_PROGRAM = "herdr";
        SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
      };
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
          Directories prepended to `PATH` in the user session, in the given
          order. This is the Hjem equivalent of home-manager's
          `home.sessionPath`, which Hjem does not provide.

          A relative entry is resolved against the user's home directory, so
          this reads cleanly and works for every configured user. An absolute
          entry is used as-is.

          Hjem's `environment.sessionVariables` can only replace a whole
          variable, and it exports through a POSIX script that does not expand
          `$HOME`. Nushell therefore prepends these entries itself, which keeps
          the inherited `PATH` intact instead of replacing it.
        '';
      };

      config = {
        environment.variables = variables;

        hjemModule =
          {
            lib,
            osConfig,
            config,
            ...
          }:
          let
            sessionPath = lib.map (
              entry: if lib.hasPrefix "/" entry then entry else "${config.directory}/${entry}"
            ) osConfig.sessionPath;
          in
          {
            environment.sessionVariables = variables;

            xdg.config.files."nushell/config.nu".text =
              mkAfter
                # nu
                ''
                  ${lib.concatMapStringsSep "\n" (
                    entry: /* nu */ ''$env.PATH = ($env.PATH | prepend "${lib.toString entry}")''
                  ) (lib.reverseList sessionPath)}
                '';
          };
      };
    };
}
