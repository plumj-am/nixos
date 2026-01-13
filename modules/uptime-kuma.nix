{
  flake.modules.nixos.uptime-kuma =
    { config, ... }:
    let
      inherit (config.networking) domain;
      inherit (config.myLib) merge;

      fqdn = "uptime.${domain}";
      port = "3001"; # String for uptime-kuma.
      HOST = "127.0.0.1";
    in
    {
      services.uptime-kuma = {
        enable = true;
        settings = {
          inherit port HOST;
        };
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        serverAliases = [ "status.${domain}" ];
        locations."/" = {
          proxyPass = "http://${HOST}:${port}";
          proxyWebsockets = true;
          extraConfig = # nginx
            ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
        };
      };
    };
}
