{ config, lib, pkgs, ... }: lib.mkIf config.isDarwin {
  environment.systemPackages = [
    pkgs.karabiner-elements
    pkgs.raycast
  ];
}