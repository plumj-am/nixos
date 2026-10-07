{
  flake.modules.nixos.matrix =
    { lib, config, ... }:
    let
      inherit (lib.modules) merge;
      inherit (config.helpers) rustic;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      fqdn = "matrix.${domain}";
      port = 8008;
    in
    {
      sops.secrets = {
        "matrix/signing-key" = {
          sopsFile = ../secrets/services/matrix.yaml;
          owner = "matrix-synapse";
          group = "matrix-synapse";
          mode = "600";
        };
        "matrix/registration-secret" = {
          sopsFile = ../secrets/services/matrix.yaml;
          owner = "matrix-synapse";
          group = "matrix-synapse";
          mode = "600";
        };
      };

      services.rustic.backups.matrix = rustic.mkBackup "matrix" {
        paths = [ "/var/lib/matrix-synapse" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      systemd.services.matrix-synapse.serviceConfig = {
        # sandboxing
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;

        # fs restrictions
        ReadWritePaths = [ "/var/lib/matrix-synapse" ];

        # network restrictions
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];

        # misc
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
      };

      services.matrix-synapse = {
        enable = true;
        withJemalloc = true;

        configureRedisLocally = true;

        settings = {
          server_name = domain;

          listeners = [
            {
              inherit port;
              bind_addresses = [ "::1" ];
              type = "http";
              tls = false;
              x_forwarded = true; # behind reverse proxy
              resources = [
                {
                  names = [
                    "client"
                    "federation"
                    "media"
                  ];
                  compress = false;
                }
              ];
            }
          ];

          database.name = "sqlite3";
          database.args.database = "/var/lib/matrix-synapse/homeserver.db";

          log_config = "/var/lib/matrix-synapse/log.yaml";
          log.root.level = "WARNING";

          enable_registration = true;
          registration_requires_token = true;

          allow_public_rooms_without_auth = true;
          allow_public_rooms_over_federation = true;

          report_stats = false;

          delete_stale_devices_after = "30d";

          redis.enabled = true;

          max_upload_size = "512M";

          media_store_path = "/var/lib/matrix-synapse/media_store";

          url_preview_enabled = true;
          dynamic_thumbnails = true;

          signing_key_path = secrets."matrix/signing-key".path;
          registration_shared_secret = secrets."matrix/registration-secret".path;

          trusted_key_servers = [ ];

          extras = [
            "url-preview"
            "user-search"
          ];
        };
      };

      services.ferronVhosts.${fqdn} = merge config.services.ferron.sslTemplate {
        config = # kdl
          ''
            # `localhost` resolves to ::1 with IPv4 fallback.
            location "/_matrix" {
                proxy "http://localhost:${toString port}/_matrix" {
                    request_header -Accept-Encoding
                }
            }

            location "/_synapse/client" {
                proxy "http://localhost:${toString port}/_synapse/client" {
                    request_header -Accept-Encoding
                }
            }

            location "/_synapse/admin" {
                proxy "http://localhost:${toString port}/_synapse/admin" {
                    request_header -Accept-Encoding
                }
            }

            ${config.services.ferron.goatCounterTemplate}
            ${config.services.ferron.headers}
          '';
      };

      # The apex host is also declared by the website-personal module, together
      # with the site's security header set, so this vhost adds only the
      # Matrix discovery endpoints.
      services.ferronVhosts.${domain} = merge config.services.ferron.sslTemplate {
        config = # kdl
          ''
            location "/.well-known/matrix/client" {
                status 200 {
                    body "{\"m.homeserver\": {\"base_url\": \"https://${fqdn}\"}}"
                }
            }

            location "/.well-known/matrix/server" {
                status 200 {
                    body "{\"m.server\": \"${fqdn}:443\"}"
                }
            }
          '';
      };
    };

  flake.modules.nixos.cinny =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) merge;
      inherit (lib.strings) toJSON;
      inherit (config.networking) domain hostName;

      fqdn = "chat.${domain}";
      root = "${pkgs.cinny}";

      cinnyConfig = {
        allowCustomHomeservers = false;
        homeserverList = [ domain ];
        defaultHomeserver = 0;

        hashRouter = {
          enabled = false;
          basename = "/";
        };

        featuredCommunities = {
          openAsDefault = false;

          servers = [
            domain
            "matrix.org"
          ];

          spaces = [ ];

          rooms = [ ];
        };
      };

      # Ferron string literals are double-quoted; escape quotes and backslashes
      # coming from the generated JSON.
      escapeFerronString = s: builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] s;
    in
    {
      assertions = singleton {
        assertion = config.services.matrix-synapse.enable;
        message = "The Cinny module should be used on the host running Matrix, but you're trying to enable it on '${hostName}'.";
      };

      services.ferronVhosts.${fqdn} = merge config.services.ferron.sslTemplate {
        inherit root;

        config = # kdl
          ''
            status 200 {
                url /config.json
                body "${escapeFerronString (toJSON cinnyConfig)}"
            }

            header -Content-Security-Policy
            header +Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain}; object-src 'self' ${domain} *.${domain}; img-src 'self' data: https: blob:; base-uri 'self'; frame-ancestors 'self';"
            header -X-Frame-Options
            header +X-Frame-Options DENY
            header -X-Content-Type-Options
            header +X-Content-Type-Options nosniff
            header -X-XSS-Protection
            header +X-XSS-Protection "1; mode=block"
            header -Permissions-Policy
            header +Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()"
            header -Referrer-Policy
            header +Referrer-Policy no-referrer

            # SPA fallback: real files and directories win, everything else
            # serves index.html.
            rewrite r"^/.+$" "/index.html" {
                last
                file false
                directory false
            }
          '';
      };
    };
}
