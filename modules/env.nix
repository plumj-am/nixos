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
