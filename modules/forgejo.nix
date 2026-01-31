{
  flake.modules.nixos.forgejo =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.networking) domain;
      inherit (config.myLib) merge mkResticBackup;
      inherit (lib) mkForce;

      fqdn = "git.${domain}";
      port = 8001;
    in
    {
      system.activationScripts.forgejo-setup-keys = lib.stringAfter [ "agenix" ] ''
        ln --symbolic --force ${config.age.secrets.forgejoSigningKey.path} /run/agenix/forgejo-signing-key
        ln --symbolic --force ${config.age.secrets.forgejoSigningKeyPub.path} /run/agenix/forgejo-signing-key.pub
      '';

      # combine AcceptEnv settings for SSH and Git protocol
      services.openssh.settings.AcceptEnv = mkForce [
        "SHELLS"
        "COLORTERM"
        "GIT_PROTOCOL"
      ];

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

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';
        locations."/".proxyPass = "http://[::1]:${toString port}";
      };
    };
}
