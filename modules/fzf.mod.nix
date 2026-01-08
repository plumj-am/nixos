{
  config.flake.modules.homeModules.fzf =
    { pkgs, ... }:
    let
      package = pkgs.fzf;
    in
    {
      packages = [ package ];
    };
}
