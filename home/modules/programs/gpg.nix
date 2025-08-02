{ pkgs, ... }:
{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    # pinentry.package = pkgs.pinentry-curses; # nicer but doesn't work with neogit
    pinentry.package = pkgs.pinentry-tty;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    defaultCacheTtl = 3600;
  };
}
