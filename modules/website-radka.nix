{
  flake.modules.nixos.website-radka =
    {
      inputs,
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib') merge;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      port = 8081;
    in
    {
      imports = singleton inputs.grove.nixosModules.radka;

      sops.secrets."radka/environment" = {
        sopsFile = ../secrets/services/radka.yaml;
        owner = "radka";
        group = "radka";
      };

      services.radka = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.radka;

        stateDir = "/var/lib/radka";
        environmentFile = secrets."radka/environment".path;
      };

      services.nginx = {
        enable = true;
        # Redirect www.dr-radka.pl to dr-radka.pl
        virtualHosts."www.${domain}" = merge config.services.nginx.sslTemplate {
          locations."/".return = "301 https://${domain}$request_uri";
        };

        virtualHosts.${domain} = merge config.services.nginx.sslTemplate {
          # TODO: fix goatcounter
          # extraConfig = ''
          #   ${config.services.nginx.goatCounterTemplate}
          # '';

          locations."/" = {
            proxyPass = "http://[::1]:${toString port}";
            extraConfig = # nginx
              ''
                # override csp for built app requirements and maintain security headers
                proxy_hide_header Content-Security-Policy;
                add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} cdn.jsdelivr.net unpkg.com *.posthog.com *.googletagmanager.com *.google-analytics.com analytics.plumj.am; object-src 'self' ${domain} *.${domain}; base-uri 'self'; frame-ancestors 'self'; form-action 'self' ${domain} *.${domain}; font-src 'self' ${domain} *.${domain} cdn.jsdelivr.net; connect-src 'self' ${domain} *.${domain} unpkg.com *.posthog.com *.googletagmanager.com *.google-analytics.com analytics.plumj.am; img-src 'self' ${domain} *.${domain} unpkg.com *.tile.openstreetmap.org www.googletagmanager.com data:;" always;
                add_header X-Frame-Options DENY always;
                add_header X-Content-Type-Options nosniff always;
                add_header X-XSS-Protection "1; mode=block" always;
                add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
                add_header Referrer-Policy strict-origin-when-cross-origin always;
              '';
          };
        };
      };
    };
}
