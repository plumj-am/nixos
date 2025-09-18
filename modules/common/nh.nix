{ lib, pkgs, ... }: let
  inherit (lib) enabled;
in {
  # nh package and configuration aligned with ncc's approach
  environment.systemPackages = [
    pkgs.nh
    pkgs.nix-output-monitor  # For enhanced output formatting
  ];

}