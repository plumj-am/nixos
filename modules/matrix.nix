{ self, config, lib, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled mkForce;

  fqdn = "matrix.${domain}";
  port = 8008;
in {
  imports = [ (self + /modules/nginx.nix) ];

  age.secrets.matrixSigningKey = {
    file  = ../hosts/plum/matrix-signing-key.age;
    owner = "matrix-synapse";
    group = "matrix-synapse";
  };

  age.secrets.matrixRegistrationSecret = {
    file  = ../hosts/plum/matrix-registration-secret.age;
    owner = "matrix-synapse";
    group = "matrix-synapse";
  };

  systemd.services.matrix-backup = {
    description = "Backup Matrix data and database";
    after       = [ "matrix-synapse.service" ];
    script      = ''
      mkdir -p /var/backup/matrix
      cp -r /var/lib/matrix-synapse /var/backup/matrix/$(date +%Y%m%d_%H%M%S)

      # keep only last 7 backups
      ls -1t /var/backup/matrix/ | tail -n +8 | xargs -r rm -rf
    '';

    serviceConfig.Type = "oneshot";
		serviceConfig.User = "matrix-synapse";
  };

  systemd.timers.matrix-backup = {
    description = "Run Matrix backup daily";
    wantedBy    = [ "timers.target" ];

    timerConfig.OnCalendar = "daily";
		timerConfig.Persistent = true;
  };

  systemd.services.matrix-synapse.serviceConfig = {
    # sandboxing
    PrivateTmp    = true;
    ProtectSystem = "strict";
    ProtectHome   = true;

    # fs restrictions
    ReadWritePaths = [ "/var/lib/matrix-synapse" ];

    # network restrictions
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

    # misc
    NoNewPrivileges  = true;
    RestrictSUIDSGID = true;
  };

  services.matrix-synapse = enabled {
    withJemalloc = true;

    configureRedisLocally = true;

    settings = let
      description = "James's Matrix Server";
    in {
      server_name = domain;

      listeners = [{
        port           = port;
        bind_addresses = [ "::1" ];
        type           = "http";
        tls            = false;
        x_forwarded    = true; # behind reverse proxy
        resources      = [{
          names    = [ "client" "federation" ];
          compress = false;
        }];
      }];

      database.name          = "sqlite3";
			database.args.database = "/var/lib/matrix-synapse/homeserver.db";

      log_config     = "/var/lib/matrix-synapse/log.yaml";
			log.root.level = "WARNING";

      enable_registration         = true;
      registration_requires_token = true;

      delete_stale_devices_after = "30d";

      redis.enabled = true;

      max_upload_size = "512M";

      signing_key_path           = config.age.secrets.matrixSigningKey.path;
      registration_shared_secret = config.age.secrets.matrixRegistrationSecret.path;

      trusted_key_servers = [];

      extras = [ "url-preview" "user-search" ];
    };
  };

  services.nginx.virtualHosts.${fqdn} = lib.merge config.services.nginx.sslTemplate {
    locations."/_matrix".proxyPass         = "http://[::1]:${toString port}";
    locations."/_synapse/client".proxyPass = "http://[::1]:${toString port}";
    locations."/_synapse/admin".proxyPass  = "http://[::1]:${toString port}";
  };

  services.nginx.virtualHosts.${domain} = lib.merge config.services.nginx.sslTemplate {
    locations."/.well-known/matrix/client".extraConfig = ''
			return 200 '{"m.homeserver": {"base_url": "https://${fqdn}"}}';
		'';

    locations."/.well-known/matrix/server".extraConfig = ''
			return 200 '{"m.server": "${fqdn}:443"}';
		'';
  };
}
