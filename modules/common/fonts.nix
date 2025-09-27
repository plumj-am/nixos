{ config, pkgs, lib, ... }: let
  inherit (lib) mkIf disabled;
in
{
  # Virtual console for login.
  console = {
    earlySetup = true;
    font       = "Lat2-Terminus16";
    packages   = [ pkgs.terminus_font ];
  };

  fonts.fontconfig = mkIf config.isServer disabled;

  fonts.packages = mkIf config.isDesktop [
    config.theme.font.mono.package
    config.theme.font.sans.package

    # Fallback for emojis and icons.
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-lgc-plus
    pkgs.noto-fonts-emoji
  ];
}

