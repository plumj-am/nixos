{
  config.flake.modules.nixos.uptime-kuma =
    { config, lib, ... }:
    let
      inherit (config.networking) domain;
      inherit (lib) enabled merge;

      fqdn = "uptime.${domain}";
      port = "3001"; # string for uptime-kuma
    in
    {
      imports = [ ./nginx.nix ];

      services.uptime-kuma = enabled {
        settings = {
          inherit port;
          HOST = "127.0.0.1";
        };
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        serverAliases = [ "status.${domain}" ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
}
