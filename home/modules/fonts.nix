{
  pkgs,
  lib,
  ...
}:
{
  programs.nix-index.enable = true;
  programs.bun.enable = true;

  home.packages = [
    pkgs.nerd-fonts.iosevka-term
  ];
}
