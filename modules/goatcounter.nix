{
  flake.modules.nixos.goatcounter =
    { lib, config, ... }:
    let
      inherit (lib.modules) merge;
      inherit (config.networking) domain;

      fqdn = "analytics.${domain}";
      port = 8007;
      address = "127.0.0.1";
    in
    {
      config = {
        services.goatcounter = {
          inherit address port;

          enable = true;
          proxy = true;
        };

        services.ferronVhosts.${fqdn} = merge config.services.ferron.sslTemplate {
          proxy = "http://${address}:${toString port}";

          config = # kdl
            ''
              ${config.services.ferron.headers}
            '';
        };
      };
    };
}
