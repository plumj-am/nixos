let
  envBase =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;

      variables = {
        EDITOR = "hx";
        SHELL = "${pkgs.nushell}/bin/nu";
        TERMINAL = "zellij";
        TERM_PROGRAM = "zellij";

        WGPU_BACKEND = "gl"; # For ashell.
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
