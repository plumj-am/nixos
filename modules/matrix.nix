let
  matrixBase =
    { config, ... }:
    let
      inherit (config.myLib) merge mkResticBackup;
      inherit (config.networking) domain;

      fqdn = "matrix.${domain}";
      port = 8008;
    in
    {
      services.restic.backups.matrix = mkResticBackup "matrix" {
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

          signing_key_path = config.age.secrets.matrixSigningKey.path;
          registration_shared_secret = config.age.secrets.matrixRegistrationSecret.path;

          trusted_key_servers = [ ];

          extras = [
            "url-preview"
            "user-search"
          ];
        };
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';
        locations."/_matrix".proxyPass = "http://[::1]:${toString port}";
        locations."/_synapse/client".proxyPass = "http://[::1]:${toString port}";
        locations."/_synapse/admin".proxyPass = "http://[::1]:${toString port}";
      };

      services.nginx.virtualHosts.${domain} = merge config.services.nginx.sslTemplate {
        locations."/.well-known/matrix/client".extraConfig = ''
          			return 200 '{"m.homeserver": {"base_url": "https://${fqdn}"}}';
          		'';

        locations."/.well-known/matrix/server".extraConfig = ''
          			return 200 '{"m.server": "${fqdn}:443"}';
          		'';
      };
    };

  cinnyBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.strings) toJSON;
      inherit (lib.lists) singleton;
      inherit (config.networking) domain hostName;
      inherit (config.myLib) merge;

      fqdn = "chat.${domain}";
      root = pkgs.cinny;

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
    in
    {
      assertions = singleton {
        assertion = config.services.matrix-synapse.enable;
        message = "The Cinny module should be used on the host running Matrix, but you're trying to enable it on '${hostName}'.";
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        inherit root;

        locations."= /config.json".extraConfig = # nginx
          ''
            default_type application/json;
            return 200 '${toJSON cinnyConfig}';
          '';

        locations."/".extraConfig = # nginx
          ''
            proxy_hide_header Content-Security-Policy;
            add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain}; object-src 'self' ${domain} *.${domain}; img-src 'self' data: https: blob:; base-uri 'self'; frame-ancestors 'self';" always;
            add_header X-Frame-Options DENY always;
            add_header X-Content-Type-Options nosniff always;
            add_header X-XSS-Protection "1; mode=block" always;
            add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
            add_header Referrer-Policy no-referrer always;
          '';

        extraConfig = # nginx
          ''
            rewrite ^/config.json$ /config.json break;
            rewrite ^/manifest.json$ /manifest.json break;

            rewrite ^/sw.js$ /sw.js break;
            rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;

            rewrite ^/public/(.*)$ /public/$1 break;
            rewrite ^/assets/(.*)$ /assets/$1 break;

            rewrite ^(.+)$ /index.html break;
          '';
      };

    };
in
{
  flake.modules.nixos.matrix = matrixBase;
  flake.modules.nixos.cinny = cinnyBase;
}
