{ lib, config, ... }: let
  inherit (lib) enabled mkIf;
in {
  home-manager.sharedModules = [{
    programs.bun = mkIf config.isDesktop enabled;
  }];
}
