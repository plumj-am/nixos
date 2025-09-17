{ pkgs, ... }:
{
  unfree.allowedNames = [ "raycast" ];

  environment.systemPackages = [
    pkgs.karabiner-elements
    pkgs.raycast
  ];
}
