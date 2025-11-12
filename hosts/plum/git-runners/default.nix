{ pkgs, lib, config, ... }: let
  inherit (lib) enabled;
in {
  age.secrets.forgejoRunnerToken.rekeyFile = ./forgejo-runner-token.age;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.${config.networking.hostName} = enabled {
      name         = config.networking.hostName;
      tokenFile    = config.age.secrets.forgejoRunnerToken.path;
      url          = "https://git.plumj.am/";
      labels       = [ "self-hosted:host" ];

      settings.cache.enabled = true;

      hostPackages = [
        pkgs.bash
        pkgs.curl
        pkgs.git
        pkgs.nix
        pkgs.nodejs
        pkgs.xz
      ];
    };
  };
}
