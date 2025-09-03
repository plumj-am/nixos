{ self, config, lib, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled mkConst;
in {
  imports = [(self + /modules/acme)];
  options.services.caddy.sslTemplate = mkConst {
    useACMEHost = domain;
  };

  options.services.caddy.headers = mkConst /* caddy */ ''
    header {
      Access-Control-Allow-Origin {$allow_origin}
      Access-Control-Allow-Methods {$allow_methods}

      Strict-Transport-Security {$hsts_header}
      Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain}; object-src 'self' ${domain} *.${domain}; base-uri 'self';"
      Referrer-Policy "no-referrer"
      X-Frame-Options "DENY"
    }
  '';

  config.networking.firewall = {
    allowedTCPPorts = [ 443 80 ];
    allowedUDPPorts = [ 443 ];
  };

  config.services.caddy = enabled {
    globalConfig = /* caddy */ ''
      {
        admin 0.0.0.0:2019
      }
    '';

    extraConfig = /* caddy */ ''
      (hsts) {
        @https {
          scheme https
        }
        header @https Strict-Transport-Security "max-age=31536000; includeSubdomains; preload"
      }

      (cors) {
        @cors_origin header Origin ~^https://(?:.+\.)?${domain}$
        @cors_methods {
          method OPTIONS
        }

        header @cors_origin {
          Access-Control-Allow-Origin {header.origin}
          Access-Control-Allow-Methods "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE"
        }

        respond @cors_methods "" 204

        ${config.services.caddy.headers}
      }
    '';
  };

  config.security.acme.users = [ "caddy" ];
}
