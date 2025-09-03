{ lib, ... }:
let
	inherit (lib) enabled;
in
{
  programs.direnv = enabled {
    enableNushellIntegration = true;

    nix-direnv = enabled;
  };
}
