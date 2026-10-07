{
  flake.modules.nixos.mealie =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) merge;
      inherit (config.helpers) rustic;
      inherit (config.networking) domain;

      fqdn = "mealie.${domain}";
    in
    {
      services.rustic.backups.mealie = rustic.mkBackup "mealie" {
        paths = [ "/var/lib/mealie" ];
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

      services.ferronVhosts.${fqdn} = merge config.services.ferron.sslTemplate {
        proxy = "http://127.0.0.1:${toString config.services.mealie.port}";

        config = # kdl
          ''
            ${config.services.ferron.headers}
          '';
      };
    };
}
