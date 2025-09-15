{ lib, config, ... }: let
  inherit (lib) enabled mkIf;
in {
  home-manager.sharedModules = [{
    programs.claude-code = mkIf config.isDesktop enabled;
  }];
}
