{
  flake.modules.hjem.env =
    { pkgs, ... }:
    {
      environment.sessionVariables = {
        EDITOR = "hx";
        SHELL = "${pkgs.nushell}/bin/nu";
        TERMINAL = "zellij";
        TERM_PROGRAM = "zellij";
      };

      # TODO: Add sessionPath equivalent in hjem?
      # home-manager.sharedModules = [{
      #   home.sessionPath = [
      #     "$HOME/.local/bin"
      #     "$HOME/.cargo/bin"
      #     "$HOME/.bun/bin"
      #   ];
      # }];
    };
}
