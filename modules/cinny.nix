{ self, config, lib, pkgs, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled;

  fqdn = "chat.${domain}";
in {
  imports = [
    (self + /modules/nginx.nix)
  ];

  # cinny web client configuration
  services.nginx.virtualHosts.${fqdn} = lib.merge config.services.nginx.sslTemplate {
    root = pkgs.cinny;

    # serve custom config.json
    locations."= /config.json".extraConfig = ''
      default_type application/json;
      return 200 '${builtins.toJSON {
        defaultHomeserver = 0;
        homeserverList = [ "matrix.${domain}" ];
        allowCustomHomeservers = false;
        hashRouter = {
          enabled = false;
        };
      }}';
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

    # static assets caching
    locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$" = {
      extraConfig = ''
        expires 1y;
      '';
    };
  };
}
