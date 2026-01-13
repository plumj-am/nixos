{ self, config, lib, pkgs, ... }: let
  inherit (config.networking) domain;
  inherit (lib) merge;
  inherit (lib.strings) toJSON;

  fqdn = "chat.${domain}";
  root = pkgs.cinny;

  cinnyConfig = {
    allowCustomHomeservers = false;
    homeserverList         = [ domain ];
    defaultHomeserver      = 0;

    hashRouter = {
      enabled  = false;
      basename = "/";
    };

    featuredCommunities = {
      openAsDefault = false;

      servers = [
        domain
        "matrix.org"
      ];

      spaces = [ ];

      rooms = [ ];
    };
  };
in {
  imports = [ (self + /modules/nginx.nix) ];


  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    inherit root;

    locations."= /config.json".extraConfig = /* nginx */ ''
      default_type application/json;
      return 200 '${toJSON cinnyConfig}';
    '';

    locations."/".extraConfig = /* nginx */ ''
      proxy_hide_header Content-Security-Policy;
      add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain}; object-src 'self' ${domain} *.${domain}; img-src 'self' data: https: blob:; base-uri 'self'; frame-ancestors 'self';" always;
      add_header X-Frame-Options DENY always;
      add_header X-Content-Type-Options nosniff always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
      add_header Referrer-Policy no-referrer always;
    '';

    extraConfig = /* nginx */ ''
      rewrite ^/config.json$ /config.json break;
      rewrite ^/manifest.json$ /manifest.json break;

      rewrite ^/sw.js$ /sw.js break;
      rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;

      rewrite ^/public/(.*)$ /public/$1 break;
      rewrite ^/assets/(.*)$ /assets/$1 break;

      rewrite ^(.+)$ /index.html break;
    '';
  };
}
