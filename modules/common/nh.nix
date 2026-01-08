{ lib, pkgs, ... }: let
  inherit (lib) enabled;
in {
  environment.systemPackages = [
    pkgs.nh
    pkgs.nix-output-monitor
  ];

}
