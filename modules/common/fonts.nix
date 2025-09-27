{ config, pkgs, lib, ... }: let
  inherit (lib) mkIf;
in
{
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

