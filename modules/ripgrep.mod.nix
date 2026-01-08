{
  config.flake.modules.homeModules.ripgrep =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;

      package = pkgs.ripgrep;
    in
    {
      environment.sessionVariables = {
        RIPGREP_CONFIG_PATH = "/home/jam/.config/ripgrep/ripgreprc";
      };

      packages = [ package ];

      xdg.config.files."ripgrep/ripgreprc".text =
        ''
          --line-number
          --smart-case
        '';
    };
}
