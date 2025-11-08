{ self, config, lib, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled mkForce;

  fqdn = "git.${domain}";
  port = 8001;
in {
  imports = [
    (self + /modules/nginx.nix)
  ];

  # combine AcceptEnv settings for SSH and Git protocol
  services.openssh.settings.AcceptEnv = mkForce "SHELLS COLORTERM GIT_PROTOCOL";


  # backup configuration for sqlite database and data
  systemd.services.forgejo-backup = {
    description = "Backup Forgejo data and database";
    after = [ "forgejo.service" ];

    script = ''
      mkdir -p /var/backup/forgejo
      cp -r /var/lib/forgejo /var/backup/forgejo/$(date +%Y%m%d_%H%M%S)

      # keep only last 7 backups
      ls -1t /var/backup/forgejo/ | tail -n +8 | xargs -r rm -rf
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "forgejo";
    };
  };

  systemd.timers.forgejo-backup = {
    description = "Run Forgejo backup daily";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  services.forgejo = enabled {
    lfs = enabled;

    user  = "forgejo";

    database = {
      type = "sqlite3";
    };


    settings = let
      description = "PlumJam's Git Forge";
    in {
      default.APP_NAME = description;

      attachment.ALLOWED_TYPES = "*/*";

      cache.ENABLED = true;

      # archive cleanup cron job
      "cron.archive_cleanup" = let
        interval = "4h";
      in {
        SCHEDULE   = "@every ${interval}";
        OLDER_THAN =           interval;
      };

      other = {
        SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
        SHOW_FOOTER_VERSION            = false;
      };

      packages.ENABLED = false;

      repository = {
        DEFAULT_BRANCH      = "master";
        DEFAULT_MERGE_STYLE = "rebase-merge";
        DEFAULT_REPO_UNITS  = "repo.code, repo.issues, repo.pulls";

        DEFAULT_PUSH_CREATE_PRIVATE = false;
        ENABLE_PUSH_CREATE_ORG      = true;
        ENABLE_PUSH_CREATE_USER     = true;

        DISABLE_STARS = true;
      };

      "repository.upload" = {
        FILE_MAX_SIZE = 100;
        MAX_FILES     = 10;
      };

      server = {
        DOMAIN       = domain;
        ROOT_URL     = "https://${fqdn}/";
        LANDING_PAGE = "/explore";

        HTTP_ADDR = "::1";
        HTTP_PORT = port;

        SSH_DOMAIN       = fqdn;
        SSH_PORT         = 22;
        START_SSH_SERVER = false;

        DISABLE_ROUTER_LOG = true;
      };

      service.DISABLE_REGISTRATION = true;

      session = {
        COOKIE_SECURE = true;
        SAME_SITE     = "strict";
      };

      "ui.meta" = {
        AUTHOR      = description;
        DESCRIPTION = description;
      };
    };
  };

  services.nginx.virtualHosts.${fqdn} = lib.merge config.services.nginx.sslTemplate {
    extraConfig = ''
      ${config.services.nginx.goatCounterTemplate}
    '';
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
