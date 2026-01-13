{
  config.flake.modules.nixos.goatcounter =
    { config, ... }:
    let
      inherit (config.network) domain;
      inherit (config.myLib) merge;

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
