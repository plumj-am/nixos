{ config, lib, ... }: let
	inherit (lib) enabled mkIf;
in
{
  home-manager.sharedModules = [{
    programs.bacon = mkIf config.isDesktop enabled;
  }];
}
