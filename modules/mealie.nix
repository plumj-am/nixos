{
  flake.modules.nixos.mealie =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) merge mkIf;
      inherit (config.helpers) rustic;
      inherit (config.networking) domain;

      fqdn = "mealie.${domain}";
    in
    {
      services.rustic.backups.mealie = rustic.mkBackup "mealie" {
        paths = singleton "/var/lib/mealie";
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };

      services.mealie = {
        enable = true;
        listenAddress = "127.0.0.1";

        database.createLocally = false; # for postgres

        settings = {
          ALLOW_SIGNUP = "False";
          BASE_URL = "https://mealie.plumj.am";

          DB_ENGINE = "sqlite";
          SQLITE_MIGRATE_JOURNAL_WAL = "True";

          TZ = "Europe/Warsaw";
        };
      };

      systemd.services.mealie.serviceConfig = {
        # `init_db` runs the full alembic migration as `ExecStartPre`. Python
        # import alone sometimes needs more than the default 90s.
        TimeoutStartSec = "10min";

        # Mealie 3.22 probes hardcoded `/run/secrets` path at startup even when
        # no secret is configured. Mask the path with an empty tmpfs so the probe
        # is silent and secrets stay hidden.
        TemporaryFileSystem =
          mkIf (config.services.mealie.credentialsFile == null) <| singleton "/run/secrets";
      };

      services.ferronVhosts.${fqdn} = merge config.services.ferron.sslTemplate {
        proxy = "http://127.0.0.1:${toString config.services.mealie.port}";

        config = # kdl
          ''
            ${config.services.ferron.headers}
          '';
      };
    };
}
