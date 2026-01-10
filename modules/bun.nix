{
  config.flake.modules.hjem.bun =
    {
      pkgs,
      lib,
      isDesktop,
      ...
    }:
    let
      inherit (lib) mkIf;

      package = pkgs.bun;
    in
    mkIf isDesktop {
      packages = [ package ];
    };
}
