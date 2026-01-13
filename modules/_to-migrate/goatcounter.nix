{
  config.flake.modules.nixos.goatcounter =
    { config, ... }:
    let
      inherit (config.network) domain;

      fqdn = "analytics.${domain}";
      port = 8007;
    in
    {
      config = {
        services.goatcounter = {
          inherit port;

          enable = true;
          proxy = true;
          address = "127.0.0.1";
        };

        services.nginx.virtualHosts.${fqdn} = lib.merge config.services.nginx.sslTemplate {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString port}";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_hide_header X-Content-Type-Options;
            '';
          };
        };
      };
    };
}
