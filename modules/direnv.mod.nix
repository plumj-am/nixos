{
  config.flake.modules.homeModules.direnv =
  {
    programs.direnv = {
      enable = true;

      integrations = {
        nushell.enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
