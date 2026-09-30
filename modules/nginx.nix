{ self, ... }:
{
  flake.modules.nixos.web-server = self.modules.nixos.nginx;
  flake.modules.nixos.nginx =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.constants) tailnet;
      inherit (config.networking) domain;
    in
    {
      config.networking.firewall = {
        allowedTCPPorts = [
          443
          80
        ];
        allowedUDPPorts = [ 443 ];
      };

      config.security.acme.users = [ "nginx" ];

      config.services.nginx = {
        enable = true;
        statusPage = true;

        recommendedBrotliSettings = true;
        recommendedGzipSettings = true;

        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        tailscaleAuth = {
          enable = true;
          expectedTailnet = tailnet;
        };

        appendHttpConfig = ''
          add_header Permissions-Policy "interest-cohort=()";
        '';

        commonHttpConfig = # nginx
          ''
            map $scheme $hsts_header {
              https "max-age=31536000; includeSubdomains; preload";
            }

            # Cache only successful responses.
            map $status $cache_header {
              200     "public";
              302     "public";
              default "no-cache";
            }

            map $http_origin $allow_origin {
              ~^https://(?:.+\.)?${domain}$ $http_origin;
              ~^https://dr-radka\.pl$ $http_origin;
              ~^https://awesome-technologies\.github\.io$ $http_origin;
              ~^https://app\.element\.io$ $http_origin;
            }

            map $http_origin $allow_methods {
              ~^https://(?:.+\.)?${domain}$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
              ~^https://dr-radka\.pl$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
              ~^https://awesome-technologies\.github\.io$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
              ~^https://app\.element\.io$ "DELETE, GET, OPTIONS, POST, PUT";
            }

            ${config.services.nginx.headers}

            proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
          '';
      };
    };
}
