{
  flake.modules.nixos.freshrss-server =
    { lib, config, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) merge;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      fqdn = "rss.${domain}";
    in
    {
      sops.secrets."rss-server/admin-password" = {
        sopsFile = ../secrets/services/rss.yaml;
        owner = "freshrss";
        mode = "400";
      };

      services.freshrss = {
        enable = true;

        api.enable = true;

        database.type = "sqlite";

        virtualHost = fqdn;
        baseUrl = "https://${fqdn}";

        defaultUser = "admin";
        passwordFile = secrets."rss-server/admin-password".path;
      };

      # Ferron terminates TLS; nginx (nixpkgs-generated PHP rules) serves PHP
      # to it on loopback only.
      services.nginx.virtualHosts.${fqdn}.listen = singleton {
        addr = "127.0.0.1";
        port = 8083;
      };

      services.ferronVhosts.${fqdn} = merge config.services.ferron.sslTemplate {
        config = # kdl
          ''
            ${config.services.ferron.headers}
            ${config.services.ferron.goatCounterTemplate}

            location "/" {
                proxy "http://127.0.0.1:8083" {
                    request_header -Accept-Encoding
                }
            }
          '';
      };
    };
}
