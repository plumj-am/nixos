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
          inherit port address;

          enable = true;
          proxy = true;
        };

        services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
          locations."/" = {
            proxyPass = "http://${address}:${toString port}";
            proxyWebsockets = true;
            extraConfig = # nginx
              ''
                proxy_hide_header X-Content-Type-Options;
              '';
          };
        };
      };
    };
}
