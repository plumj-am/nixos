{ self, config, lib, pkgs, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled mkConst;
in {
  imports = [ (self + /modules/acme) ];

  options.services.nginx.sslTemplate = mkConst {
    forceSSL    = true;
    quic        = true;
    useACMEHost = domain;
  };

  options.services.nginx.headers = mkConst /* nginx */ ''
    proxy_hide_header Access-Control-Allow-Origin;
    add_header Access-Control-Allow-Origin $allow_origin always;

    ${config.services.nginx.headersNoAccessControlOrigin}
  '';

  options.services.nginx.headersNoAccessControlOrigin = mkConst /* nginx */ ''
    proxy_hide_header Access-Control-Allow-Methods;
    add_header Access-Control-Allow-Methods $allow_methods always;

    proxy_hide_header Strict-Transport-Security;
    add_header Strict-Transport-Security $hsts_header always;

    proxy_hide_header Content-Security-Policy;
    add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain}; object-src 'self' ${domain} *.${domain}; img-src 'self' data: https:; base-uri 'self'; frame-ancestors 'self';" always;

    proxy_hide_header Referrer-Policy;
    add_header Referrer-Policy no-referrer always;

    proxy_hide_header X-Frame-Options;
    add_header X-Frame-Options DENY always;

    # SECURITY: Additional 2024 security headers
    proxy_hide_header X-Content-Type-Options;
    add_header X-Content-Type-Options nosniff always;

    proxy_hide_header X-XSS-Protection;
    add_header X-XSS-Protection "1; mode=block" always;

    proxy_hide_header Permissions-Policy;
    add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
  '';

  config.networking.firewall = {
    allowedTCPPorts = [ 443 80 ];
    allowedUDPPorts = [ 443 ];
  };

  config.services.prometheus.exporters.nginx = enabled {
    listenAddress = "[::]";
  };

  config.security.acme.users = [ "nginx" ];

  config.services.nginx = enabled {
    package = pkgs.nginxQuic;

    statusPage = true;

    recommendedBrotliSettings = true;
    recommendedGzipSettings   = true;

    recommendedOptimisation   = true;
    recommendedProxySettings  = true;
    recommendedTlsSettings    = true;

    commonHttpConfig = /* nginx */ ''
      map $scheme $hsts_header {
        https "max-age=31536000; includeSubdomains; preload";
      }

      map $http_origin $allow_origin {
        ~^https://(?:.+\.)?${domain}$ $http_origin;
        ~^https://awesome-technologies\.github\.io$ $http_origin;
      }

      map $http_origin $allow_methods {
        ~^https://(?:.+\.)?${domain}$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
        ~^https://awesome-technologies\.github\.io$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
      }

      ${config.services.nginx.headers}

      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';
  };
}
