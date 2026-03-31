{
  flake.modules.nixos.docker-rootless = {
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true; # Doesn't seem to work?
    };
    # We can do this instead.
    environment.sessionVariables = {
      DOCKER_HOST = "unix:///run/user/1000/docker.sock";
    };
  };
}
