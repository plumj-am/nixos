{ config, pkgs, lib, ... }: let
  inherit (lib) mkIf;
in
{
  fonts.packages = mkIf config.isDesktop [ pkgs.nerd-fonts.iosevka-term ];
}

