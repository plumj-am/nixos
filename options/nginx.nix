{ self, ... }:
{
  flake.modules.nixos.nginx = self.modules.nixos.nginx-options;
  flake.modules.nixos.nginx-options =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) mkForce;
      inherit (lib.options) mkConst;
      inherit (config.networking) domain;
    in
    {
      options.services.nginx.sslTemplate = mkConst {
        forceSSL = mkForce true;
        quic = true;
        useACMEHost = mkForce domain;
      };

      options.services.nginx.goatCounterTemplate =
        # nginx
        mkConst ''
          proxy_set_header Accept-Encoding "";
          sub_filter "</head>" '<script data-goatcounter="https://analytics.plumj.am/count" async src="//analytics.plumj.am/count.js"></script></head>';
          sub_filter_last_modified on;
          sub_filter_once on;
        '';

      options.services.nginx.headers =
        # nginx
        mkConst ''
          proxy_hide_header Access-Control-Allow-Origin;
          add_header Access-Control-Allow-Origin $allow_origin always;

          ${config.services.nginx.headersNoAccessControlOrigin}
        '';

      options.services.nginx.headersNoAccessControlOrigin =
        # nginx
        mkConst ''
          proxy_hide_header Access-Control-Allow-Methods;
          add_header Access-Control-Allow-Methods $allow_methods always;

          proxy_hide_header Strict-Transport-Security;
          add_header Strict-Transport-Security $hsts_header always;

          proxy_hide_header Content-Security-Policy;
          add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com https://cdn.tailwindcss.com https://unpkg.com/lucide@0.473.0; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com *.${domain}; object-src 'self' ${domain} *.${domain}; img-src 'self' blob: data: https:; base-uri 'self'; frame-ancestors 'self';" always;

          proxy_hide_header Referrer-Policy;
          add_header Referrer-Policy no-referrer always;

          proxy_hide_header X-Frame-Options;
          add_header X-Frame-Options DENY always;

          proxy_hide_header X-Content-Type-Options;
          add_header X-Content-Type-Options nosniff always;

          proxy_hide_header X-XSS-Protection;
          add_header X-XSS-Protection "1; mode=block" always;

          proxy_hide_header Permissions-Policy;
          add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
        '';
    };
}
