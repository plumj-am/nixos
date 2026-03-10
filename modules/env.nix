let
  envBase =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;

      # TODO: Make an option.
      variables = {
        EDITOR = "zeditor --wait";
        SHELL = getExe pkgs.nushell;
        TERMINAL = "zellij";
        TERM_PROGRAM = "zellij";
        WGPU_BACKEND = "gl";
        SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
      };
    in
    {
      environment.variables = variables;

      hjem.extraModules = singleton {
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

in
{
  flake.modules.nixos.env = envBase;
  flake.modules.darwin.env = envBase;
}
