{ lib, ... }: let
  inherit (lib) enabled;
in {
  virtualisation.docker.rootless = enabled {
    setSocketVariable = true; # Doesn't seem to work?
  };
  # We can do this instead.
  environment.sessionVariables.DOCKER_HOST = "unix:///run/user/1000/docker.sock";
}
