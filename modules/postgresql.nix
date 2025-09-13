{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkForce mkOverride mkValue flip map;
in {
  options.services.postgresql.ensure = mkValue [];

  config.services.postgresql = enabled {
    package = pkgs.postgresql_17;

    enableJIT   = true;
    enableTCPIP = true;

    settings.listen_addresses = mkForce "::";
    authentication            = mkOverride 10 ''
      #     DATABASE USER        AUTHENTICATION
      local all      all         peer

      #     DATABASE USER ADDRESS AUTHENTICATION
      host  all      all  ::/0    md5
    '';

    ensure = [ "postgres" "root" ];

    initdbArgs      = [ "--locale=C" "--encoding=UTF8" ];
    ensureDatabases = config.services.postgresql.ensure;

    ensureUsers = flip map config.services.postgresql.ensure (name: {
      inherit name;

      ensureDBOwnership = true;

      ensureClauses = {
        login       = true;
        superuser   = name == "postgres" || name == "root";
      };
    });
  };

  config.environment.systemPackages = [
    config.services.postgresql.package
  ];
}