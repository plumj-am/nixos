{ lib, config, ... }:
let
	inherit (lib) enabled mkIf;
in
{
  home-manager.sharedModules = [{
    programs.direnv = mkIf config.isDesktop (enabled {
      enableNushellIntegration = true;

      nix-direnv = enabled;
    });
  }];
}
