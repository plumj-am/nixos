{ config, lib, ... }: let
  inherit (lib) enabled;
in {
  
  services.github2forgejo = enabled {
    environmentFile = config.age.secrets.github2forgejoEnvironment.path;
  };
}
