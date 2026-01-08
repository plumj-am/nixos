{
  config.flake.modules.homeModules.jq =
    { pkgs, ... }:
    let
      package = pkgs.jq;
    in
    {
      packages = [ package ];
    };
}
