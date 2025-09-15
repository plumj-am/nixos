{ pkgs, lib, ... }:
let
	inherit (lib) enabled;
in
{
  home-manager.sharedModules = [{
    programs.gpg = enabled;

    services.gpg-agent = enabled {
    # pinentry.package = pkgs.pinentry-curses; # nicer but doesn't work with neogit
    pinentry.package = pkgs.pinentry-tty;

    enableNushellIntegration = true;
    enableBashIntegration    = true;

    defaultCacheTtl = 3600;
    };
  }];
}
