{ pkgs, lib, config, ... }: let
  inherit (lib) enabled disabled;
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
  services.gitea-actions-runner.instances.${config.networking.hostName} = enabled {
    name         = config.networking.hostName;
    tokenFile    = config.age.secrets.forgejoRunnerToken.path;
    url          = "https://git.plumj.am";
    labels       = [ "self-hosted:host" ];
    hostPackages = [
      pkgs.bash
      pkgs.curl
      pkgs.git
      pkgs.nix
      pkgs.nodejs
      pkgs.xz
    ];

    settings = {
      runner = {
        file             = ".runner";
        timeout          = "3h";
        shutdown_timeout = "3h";
        fetch_timeout    = "10s";
        fetch_interval   = "2s";
        report_interval  = "1s";
      };
      cache = {
        enabled                    = true;
        port                       = 0;
        dir                        = "";
        external_server            = "";
        secret                     = "";
        host                       = "";
        proxy_port                 = 0;
        actions_cache_url_override = "";
      };
    };
  };
}
