{ inputs, ... }:
{
  flake.modules.nixos.forgejo =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib) mkForce;
      inherit (config.myLib) merge mkResticBackup;
      inherit (config.age) secrets;
      inherit (config.networking) domain hostName;

      fqdn = "git.${domain}";
      port = 8001;
      mqPort = 8006;
    in
    {
      imports = singleton inputs.gitea-mq.nixosModules.default;

      services.postgresql.ensure = singleton "gitea-mq";

      assertions = [
        {
          assertion = hostName == "plum";
          message = "The forgejo module should only be used on the 'plum' host, but you're trying to enable it on '${hostName}'.";
        }
      ];

      system.activationScripts.forgejo-setup-keys = lib.stringAfter [ "agenix" ] ''
        ln --symbolic --force ${config.age.secrets.forgejoSigningKey.path} /run/agenix/forgejo-signing-key
        ln --symbolic --force ${config.age.secrets.forgejoSigningKeyPub.path} /run/agenix/forgejo-signing-key.pub
      '';

      services.openssh.settings = {
        AllowUsers = singleton "forgejo";
        AllowGroups = singleton "forgejo";

        AcceptEnv = mkForce [
          "SHELLS"
          "COLORTERM"
          "GIT_PROTOCOL"
        ];
      };

      services.restic.backups.forgejo = mkResticBackup "forgejo" {
        paths = [ "/var/lib/forgejo" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      services.forgejo = {
        enable = true;
        package = pkgs.forgejo; # The service version is ~11 so better to specify and get the latest.
        lfs.enable = true;

        user = "forgejo";

        database = {
          type = "sqlite3";
        };

        settings =
          let
            description = "PlumJam's Git Forge";
          in
          {
            default.APP_NAME = description;

            attachment.ALLOWED_TYPES = "*/*";

            cache.ENABLED = true;

            admin.DISABLE_REGULAR_ORG_CREATION = true;

            # archive cleanup cron job
            "cron.archive_cleanup" =
              let
                interval = "4h";
              in
              {
                SCHEDULE = "@every ${interval}";
                OLDER_THAN = interval;
              };

            other = {
              SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
              SHOW_FOOTER_VERSION = false;
            };

            packages.ENABLED = true;

            repository = {
              DEFAULT_BRANCH = "master";
              DEFAULT_MERGE_STYLE = "merge";
              DEFAULT_UPDATE_STYLE = "merge";
              DEFAULT_REPO_UNITS = "repo.code,repo.issues,repo.pulls,repo.actions";

              DEFAULT_CLOSE_ISSUES_VIA_COMMITS_IN_ANY_BRANCH = true;
              DEFAULT_PUSH_CREATE_PRIVATE = false;
              ENABLE_PUSH_CREATE_ORG = true;
              ENABLE_PUSH_CREATE_USER = true;

              DISABLE_STARS = true;
            };

            "repository.signing" = {
              FORMAT = "ssh";
              SIGNING_KEY = "/run/agenix/forgejo-signing-key.pub";
              MERGES = "always";
            };

            "repository.upload" = {
              FILE_MAX_SIZE = 100;
              MAX_FILES = 10;
            };

            server = {
              DOMAIN = domain;
              ROOT_URL = "https://${fqdn}/";
              LANDING_PAGE = "/explore";

              HTTP_ADDR = "::1";
              HTTP_PORT = port;

              SSH_DOMAIN = fqdn;
              SSH_PORT = 22;
              START_SSH_SERVER = false;

              DISABLE_ROUTER_LOG = true;
              OFFLINE_MODE = false; # For Gravatar.
            };

            service.DISABLE_REGISTRATION = true;

            session = {
              COOKIE_SECURE = true;
              SAME_SITE = "strict";
            };

            "ui.meta" = {
              AUTHOR = description;
              DESCRIPTION = description;
            };
          };
      };

      age.secrets = {
        renovateBotToken = {
          rekeyFile = ../secrets/renovate-bot-token.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
        renovateGitHubToken = {
          rekeyFile = ../secrets/renovate-github-token.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
        renovateSigningKey = {
          rekeyFile = ../secrets/renovate-signing-key.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
        renovateSigningKeyPub = {
          rekeyFile = ../secrets/renovate-signing-key-pub.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
        forgejoAccessToken.rekeyFile = ../secrets/forgejo-access-token.age;

        giteamqHtpasswd = {
          rekeyFile = ../secrets/gitea-mq-htpasswd.age;
          owner = "nginx";
          group = "nginx";
          mode = "0400";
        };
        giteamqWebhookSecret.rekeyFile = ../secrets/gitea-mq-webhook-secret.age;
      };

      users.users.renovate = {
        isSystemUser = true;
        group = "renovate";
      };
      users.groups.renovate = { };

      systemd.services.renovate.serviceConfig.DynamicUser = mkForce false;
      services.renovate = {
        enable = true;
        runtimePackages = [
          pkgs.cargo # I don't think it not being nightly matters here.
          pkgs.openssh # For ssh-keygen.
        ];
        schedule = "*:0/10";
        settings = {
          platform = "forgejo";
          endpoint = "https://git.plumj.am";
          autodiscover = true;
          autodiscoverFilter = [ "PlumJam/docpad" ];
          onboardingPrTitle = "renovate: Configure";
          configFileNames = [ ".forgejo/renovate.json" ];
          productLinks = { };
        };

        credentials = {
          RENOVATE_TOKEN = config.age.secrets.renovateBotToken.path;
          RENOVATE_GITHUB_COM_TOKEN = config.age.secrets.renovateGitHubToken.path;
          RENOVATE_GIT_PRIVATE_KEY = config.age.secrets.renovateSigningKey.path;
        };
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
          client_max_body_size 75M;
        '';
        locations."/".proxyPass = "http://[::1]:${toString port}";

        locations."= /robots.txt".alias = ./robots.txt;
      };

      services.gitea-mq = {
        enable = true;
        giteaUrl = "https://${fqdn}";

        repos = [ "PlumJam/docpad" ];
        externalUrl = "https://mq.${domain}";
        listenAddr = "127.0.0.1:${toString mqPort}";
        databaseUrl = "postgres:///gitea-mq?host=/run/postgresql";
        logLevel = "debug";
        hideRefFromClients = false;

        giteaTokenFile = secrets.forgejoAccessToken.path;
        webhookSecretFile = secrets.giteamqWebhookSecret.path;
      };

      services.nginx.virtualHosts."mq.${domain}" = merge config.services.nginx.sslTemplate {
        locations."/" = {
          # basicAuthFile = config.age.secrets.giteamqHtpasswd.path;
          proxyPass = "http://127.0.0.1:${toString mqPort}";
        };
      };
    };
}
