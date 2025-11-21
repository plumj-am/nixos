{ config, lib, ... }: let
  inherit (lib) disabled;
in {

  services.github2forgejo = disabled {
    environmentFile = config.age.secrets.github2forgejoEnvironment.path;
  };
}
