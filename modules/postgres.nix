{
  flake.modules.nixos.postgres =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.myLib) mkValue;
      inherit (lib.modules) mkForce mkOverride;
      inherit (lib.trivial) flip;
    in
    {
      config.services.prometheus.exporters.postgres = {
        enable = true;
        listenAddress = "[::]";
        runAsLocalSuperUser = true;
      };

      config.environment.systemPackages = [ config.services.postgresql.package ];

      options.services.postgresql.ensure = mkValue [ ];

      config.services.postgresql = {
        enable = true;
        package = pkgs.postgresql_17;

        enableJIT = true;
        enableTCPIP = true;

        settings.listen_addresses = mkForce "::";
        authentication =
          mkOverride 10 # ini
            ''
              #     DATABASE USER         AUTHENTICATION
              local all      all          peer

              #     DATABASE USER ADDRESS AUTHENTICATION
              host  all      all  ::/0    md5
            '';

        initdbArgs = [
          "--locale=C"
          "--encoding=UTF8"
        ];

        ensure = [
          "postgres"
          "root"
        ];

        ensureDatabases = config.services.postgresql.ensure;

        ensureUsers = flip map config.services.postgresql.ensure (name: {
          inherit name;

          ensureDBOwnership = true;

          ensureClauses = {
            login = true;
            superuser = name == "postgres" || name == "root";
          };
        });
      };
    };
}
