{
  config.flake.modules.homeModules.bacon =
    { pkgs, ... }:
    let
      package = pkgs.bacon;
    in
    {
      packages = [ package ];
    };
}
