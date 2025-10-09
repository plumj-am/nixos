{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.gcc
    pkgs.gnumake
    pkgs.wget
  ];
}
