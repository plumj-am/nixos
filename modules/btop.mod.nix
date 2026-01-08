{
  config.flake.modules.homeModules.btop =
    { pkgs, ... }:
    let
      package = pkgs.btop;
    in
    {
      packages = [ package ];
    };
}
