{ self, ... }:
{
  flake.modules.nixos.ferron = self.modules.nixos.ferron-options;
  flake.modules.nixos.ferron-options =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.options) mkConst;
      inherit (config.networking) domain;
    in
    {
      options.services.ferron.sslTemplate = mkConst {
        tls.cert = "/var/lib/acme/${domain}/fullchain.pem";
        tls.key = "/var/lib/acme/${domain}/key.pem";
      };

      # Injects the GoatCounter snippet into text/html response bodies.
      # When proxying, the proxy block MUST also send
      # `request_header -Accept-Encoding` so the upstream answers
      # uncompressed and `replace` is not skipped.
      options.services.ferron.goatCounterTemplate =
        mkConst
          # kdl
          ''
            replace "</head>" "<script data-goatcounter=\"https://analytics.plumj.am/count\" async src=\"//analytics.plumj.am/count.js\"></script></head>"
            replace_filter_types "text/html"
            replace_last_modified
            compressed false
            dynamic_compressed false
          '';

      options.services.ferron.headers =
        mkConst
          # kdl
          ''
            match cors_full_origin {
                request.header.origin ~ r"^https://(?:(?:.+\.)?${domain}|dr-radka\.pl|awesome-technologies\.github\.io)$"
            }

            match cors_el_origin {
                request.header.origin ~ r"^https://app\.element\.io$"
            }

            if cors_full_origin {
                header -Access-Control-Allow-Origin
                header +Access-Control-Allow-Origin "{{request.header.origin}}"
                header -Access-Control-Allow-Methods
                header +Access-Control-Allow-Methods "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE"
            }

            if cors_el_origin {
                header -Access-Control-Allow-Origin
                header +Access-Control-Allow-Origin "{{request.header.origin}}"
                header -Access-Control-Allow-Methods
                header +Access-Control-Allow-Methods "DELETE, GET, OPTIONS, POST, PUT"
            }

            ${config.services.ferron.headersNoAccessControlOrigin}
          '';

      options.services.ferron.headersNoAccessControlOrigin =
        mkConst
          # kdl
          ''
            header -Strict-Transport-Security
            header +Strict-Transport-Security "max-age=31536000; includeSubdomains; preload"
            header -Content-Security-Policy
            header +Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com https://cdn.tailwindcss.com https://unpkg.com/lucide@0.473.0; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com *.${domain}; object-src 'self' ${domain} *.${domain}; img-src 'self' blob: data: https:; base-uri 'self'; frame-ancestors 'self';"
            header -Referrer-Policy
            header +Referrer-Policy no-referrer
            header -X-Frame-Options
            header +X-Frame-Options DENY
            header -X-Content-Type-Options
            header +X-Content-Type-Options nosniff
            header -X-XSS-Protection
            header +X-XSS-Protection "1; mode=block"
            header -Permissions-Policy
            header +Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()"
            header +Permissions-Policy "interest-cohort=()"
          '';
    };
}
