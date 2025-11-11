{ pkgs, lib, config, ... }: let
  inherit (lib) enabled;
in {
  age.secrets.githubRunnerToken.rekeyFile = ./github-runner-token.age;
  services.github-runners.${config.networking.hostName} = enabled {
    name          = config.networking.hostName;
    tokenFile     = config.age.secrets.githubRunnerToken.path;
    url           = "https://github.com/plumj-am/docpad";
    user          = "build";
    extraPackages = [
      pkgs.curl
      pkgs.xz
    ];
  };

  age.secrets.forgejoRunnerToken.rekeyFile = ./forgejo-runner-token.age;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.${config.networking.hostName} = enabled {
      name         = config.networking.hostName;
      tokenFile    = config.age.secrets.forgejoRunnerToken.path;
      url          = "https://git.plumj.am/";
      labels       = [ "self-hosted:host" ];
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
