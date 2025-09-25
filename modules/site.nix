{ self, config, lib, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled merge;

  fqdn = domain;
  root = "/var/www/site";
in {
  imports = [(self + /modules/nginx.nix)];

  services.nginx = enabled {
    virtualHosts."www.${fqdn}" = merge config.services.nginx.sslTemplate {
      locations."/".return = "301 https://${fqdn}$request_uri";
    };

    virtualHosts."nerd.${fqdn}" = merge config.services.nginx.sslTemplate {

      locations."/" = {
        tryFiles = "$uri $uri.html $uri/index.html =404";
        extraConfig = ''
          proxy_hide_header Content-Security-Policy;
          add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com; script-src-elem 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com; img-src 'self' data: https: ghchart.rshah.org;" always;
          add_header X-Frame-Options DENY always;
          add_header X-Content-Type-Options nosniff always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
          add_header Referrer-Policy no-referrer always;
        '';
      };

      locations."~ ^/assets/(fonts|icons|images)/".extraConfig = /* nginx */ ''
        expires max;
        ${config.services.nginx.headers}
        add_header Cache-Control $cache_header always;
      '';

      extraConfig = /* nginx */ ''
        error_page 404 /404.html;

        ${config.services.nginx.goatCounterTemplate}
      '';

      locations."/404".extraConfig = /* nginx */ ''
        internal;
      '';
    };

    virtualHosts._ = merge config.services.nginx.sslTemplate {
      locations."/".return = "301 https://${fqdn}/404";
    };

    virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
      inherit root;

      locations."/" = {
        tryFiles = "$uri $uri.html $uri/index.html =404";
        extraConfig = ''
          proxy_hide_header Content-Security-Policy;
          add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com; script-src-elem 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com; img-src 'self' data: https: ghchart.rshah.org;" always;
          add_header X-Frame-Options DENY always;
          add_header X-Content-Type-Options nosniff always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
          add_header Referrer-Policy no-referrer always;
        '';
      };

      locations."~ ^/assets/(fonts|icons|images)/".extraConfig = /* nginx */ ''
        expires max;
        ${config.services.nginx.headers}
        add_header Cache-Control $cache_header always;
      '';

      extraConfig = /* nginx */ ''
        error_page 404 /404.html;

        ${config.services.nginx.goatCounterTemplate}
      '';

      locations."/404".extraConfig = /* nginx */ ''
        internal;
      '';
    };
  };
}
