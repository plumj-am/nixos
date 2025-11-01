{ config, pkgs, lib, ... }: let
  inherit (lib) mkIf disabled;
in
{
  config.theme.font = {
    size.small  = 12;
    size.term   = 15;
    size.normal = 16;
    size.big    = 20;

    mono.name    = "JetBrainsMono Nerd Font";
    mono.family  = "JetBrainsMono Nerd Font Mono";
    mono.package = pkgs.nerd-fonts.jetbrains-mono;

    sans.name    = "Lexend";
    sans.package = pkgs.lexend;
  };

  # Virtual console for login.
  config.console = {
    earlySetup = true;
    font       = "Lat2-Terminus16";
    packages   = [ pkgs.terminus_font ];
  };

  config.fonts.fontconfig = mkIf config.isServer disabled;

  config.fonts.packages = mkIf config.isDesktop [
    config.theme.font.mono.package
    config.theme.font.sans.package

    # Fallback for emojis and icons.
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-lgc-plus
    pkgs.noto-fonts-emoji
  ];
}

