{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.karabiner-elements
    pkgs.raycast
  ];
}
