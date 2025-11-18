{ lib, ... }: let
  inherit (lib) enabled;
in {
  virtualisation.docker.rootless = enabled {
    setSocketVariable = true;
  };
}
