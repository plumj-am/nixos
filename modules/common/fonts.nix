{ config, pkgs, lib, ... }: let
  inherit (lib) mkIf;
in
{
  fonts.packages = mkIf config.isDesktop [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.symbols-only  # Fallback for missing icons
    pkgs.lexend
  ];
}

