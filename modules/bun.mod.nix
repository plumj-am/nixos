{
  config.flake.modules.homeModules.bun =
    { pkgs, lib, config, ... }:
    let
      inherit (lib) mkIf;

      package = pkgs.bun;
    in
    mkIf config.isDesktop {
      packages = [ package ];
    };
}
