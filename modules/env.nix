{
  flake.modules.common.env =
    { pkgs, lib, ... }:
    let
      inherit (lib.meta) getExe;

      # TODO: Make an option.
      variables = {
        EDITOR = "hx";
        SHELL = getExe pkgs.nushell;
        TERMINAL = "zellij";
        TERM_PROGRAM = "zellij";
        WGPU_BACKEND = "gl";
        SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
      };
    in
    {
      environment.variables = variables;

      hjem.extraModule = {
        environment.sessionVariables = variables;

        # TODO: Add sessionPath equivalent in hjem?
        # home-manager.sharedModules = [{
        #   home.sessionPath = [
        #     "$HOME/.local/bin"
        #     "$HOME/.cargo/bin"
        #     "$HOME/.bun/bin"
        #   ];
        # }];
      };
    };
}
