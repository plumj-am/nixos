{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktop {
  programs.thunar = enabled;

  environment.systemPackages = [
    pkgs.xfce.tumbler
  ];
}