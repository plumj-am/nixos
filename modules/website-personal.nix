{
  flake.modules.nixos.website-personal =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) merge;
      inherit (config.networking) domain;

      fqdn = domain;
      root = "/var/www/site";
    in
    {
      services.ferronVhosts = {
        "www.${fqdn}" = merge config.services.ferron.sslTemplate {
          config = # kdl
            ''
              status 301 {
                  location "https://${fqdn}{{request.uri}}"
              }

              ${config.services.ferron.headers}
            '';
        };

        "nerd.${fqdn}" = merge config.services.ferron.sslTemplate {
          root = "${root}/nerd";

          config = # kdl
            ''
              error_page 404 ${root}/nerd/404.html

              header -Content-Security-Policy
              header +Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com https://kit.fontawesome.com; script-src-elem 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com https://kit.fontawesome.com; img-src 'self' data: https: ghchart.rshah.org;"
              header -X-Frame-Options
              header +X-Frame-Options DENY
              header -X-Content-Type-Options
              header +X-Content-Type-Options nosniff
              header -X-XSS-Protection
              header +X-XSS-Protection "1; mode=block"
              header -Permissions-Policy
              header +Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()"
              header -Referrer-Policy
              header +Referrer-Policy no-referrer

              ${config.services.ferron.goatCounterTemplate}

              match assets_request {
                  request.uri.path ~ r"^/assets/(fonts|icons|images)/"
              }

              if assets_request {
                  file_cache_control "max-age=31536000, public"
              }

              rewrite r"^(.*[^/])$" "$1.html" {
                  last
                  file false
                  directory false
              }
            '';
        };

        # No catch-all host: explicit-port blocks flip the shared port to
        # HTTPS (ferron 3.0.0-rc.9), and a bare `*` block bleeds `status`
        # into named hosts. Unknown hosts get ferron's default 404; the
        # nginx-era `_` 301 to /404 is dropped deliberately.

        ${fqdn} = merge config.services.ferron.sslTemplate {
          inherit root;

          config = # kdl
            ''
              error_page 404 ${root}/404.html

              header -Content-Security-Policy
              header +Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com/*; script-src-elem 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com https://kit.fontawesome.com; img-src 'self' data: https: ghchart.rshah.org;"
              header -X-Frame-Options
              header +X-Frame-Options DENY
              header -X-Content-Type-Options
              header +X-Content-Type-Options nosniff
              header -X-XSS-Protection
              header +X-XSS-Protection "1; mode=block"
              header -Permissions-Policy
              header +Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()"
              header -Referrer-Policy
              header +Referrer-Policy no-referrer

              ${config.services.ferron.goatCounterTemplate}

              match assets_request {
                  request.uri.path ~ r"^/assets/(fonts|icons|images)/"
              }

              if assets_request {
                  file_cache_control "max-age=31536000, public"
              }

              match public_request {
                  request.uri.path ~ r"^/public/"
              }

              if public_request {
                  file_cache_control "max-age=31536000, public"
                  header -Access-Control-Allow-Origin
                  header +Access-Control-Allow-Origin "*"
              }

              rewrite r"^(.*[^/])$" "$1.html" {
                  last
                  file false
                  directory false
              }
            '';
        };
      };

      systemd.tmpfiles.rules = [
        "d ${root} 0755 ferron ferron -"
        "d ${root}/public 0755 ferron ferron -"
        "d ${root}/nerd 0755 ferron ferron -"
      ];
    };
}
