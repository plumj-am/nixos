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
      inherit (lib.lists) reverseList;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter;
      inherit (lib.strings) concatMapStringsSep hasPrefix;

      # TODO: Make an option.
      variables = {
        EDITOR = "hx";
        SHELL = getExe pkgs.nushell;
        TERMINAL = "tern";
        TERM_PROGRAM = "tern";
        SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
      };
    in
    {
      config = {
        environment.variables = variables;

        hjemModule =
          {
            osConfig,
            config,
            ...
          }:
          let
            sessionPath = map (
              entry: if hasPrefix "/" entry then entry else "${config.directory}/${entry}"
            ) osConfig.sessionPath;
          in
          {
            environment.sessionVariables = variables;

            xdg.config.files."nushell/config.nu".text =
              mkAfter
                # nu
                ''
                  ${
                    concatMapStringsSep "\n" (
                      entry: # nu
                      ''
                        $env.PATH = ($env.PATH | append "${toString entry}")
                      ''
                    )
                    <| reverseList sessionPath
                  }
                '';
          };
      };
    };
}
