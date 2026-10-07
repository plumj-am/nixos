{
  flake.modules.nixos.forgejo =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) merge mkForce;
      inherit (config.helpers) rustic;
      inherit (config.networking) domain hostName;

      fqdn = "git.${domain}";
      port = 8001;

      # Served statically instead of proxied (replaces the old nginx
      # `alias = ./robots.txt`). `writeTextDir` puts the file at the root.
      robotsRoot = pkgs.writeTextDir "robots.txt" (builtins.readFile ./robots.txt);
    in
    {
      sops.secrets = {
        "forgejo/signing-key" = {
          sopsFile = ../secrets/services/forgejo.yaml;
          owner = "forgejo";
        };
        "forgejo/signing-key-pub" = {
          sopsFile = ../secrets/services/forgejo.yaml;
          owner = "forgejo";
        };
        "forgejo/admin-password".sopsFile = ../secrets/services/forgejo.yaml;
      };

      assertions = singleton {
        assertion = hostName == "plum";
        message = "The forgejo module should only be used on the 'plum' host, but you're trying to enable it on '${hostName}'.";
      };

      services.openssh.settings = {
        AllowUsers = singleton "forgejo";
        AllowGroups = singleton "forgejo";

        AcceptEnv = mkForce [
          "SHELLS"
          "COLORTERM"
          "GIT_PROTOCOL"
        ];
      };

      services.rustic.backups.forgejo = rustic.mkBackup "forgejo" {
        paths = singleton "/var/lib/forgejo";
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      services.forgejo = {
        enable = true;
        package = pkgs.forgejo.overrideAttrs (old: {
          patches = old.patches ++ [
            # ./patches/0001-lix-Make-a-Code-Review-Gerrit-tab.patch
            ./patches/0002-lix-link-gerrit-cl-and-change-ids.patch
          ];

          # - no network in sandbox
          # - perl banned (see ./nuke.nix)
          checkFlags = (old.checkFlags or [ ]) ++ [
            "-skip"
            "TestGrepCanHazRegexOnDemand|TestCaptcha|TestDNSUpdate|TestMigrateRepository|TestURLAllowedSSH|TestMigrateWhiteBlocklist"
          ];
        });

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
              SIGNING_KEY = "/run/secrets/forgejo/signing-key-pub";
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

            webhook.ALLOWED_HOST_LIST = "127.0.0.1,::1,localhost";
          };
      };

      services.ferronVhosts.${fqdn} = merge config.services.ferron.sslTemplate {
        config = # kdl
          ''
            ${config.services.ferron.headers}

            match robots_txt {
                request.uri.path == "/robots.txt"
            }

            if robots_txt {
                root ${robotsRoot}
            }

            if_not robots_txt {
                proxy "http://localhost:${toString port}" {
                    request_header -Accept-Encoding
                }
            }

            ${config.services.ferron.goatCounterTemplate}
          '';
      };
    };
}
