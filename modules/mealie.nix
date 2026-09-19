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

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.mealie.port}";
      };
    };
}
