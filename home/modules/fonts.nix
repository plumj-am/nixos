{
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    pkgs.nerd-fonts.iosevka-term
  ];
}
