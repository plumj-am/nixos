{
  config.flake.modules.homeModules.fd =
    { pkgs, ... }:
    let
      package = pkgs.fd;
    in
    {
      packages = [ package ];
    };
}
