{
  flake.modules.nixos.website-radka =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) merge;
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

      services.ferronVhosts = {
        # Redirect www.dr-radka.pl to dr-radka.pl
        "www.${domain}" = merge config.services.ferron.sslTemplate {
          config = # kdl
            ''
              status 301 {
                  location "https://${domain}{{request.uri}}"
              }
            '';
        };

        ${domain} = merge config.services.ferron.sslTemplate {
          # TODO: fix goatcounter
          # `localhost` resolves to ::1 with IPv4 fallback.
          proxy = "http://localhost:${toString port}";

          config = # kdl
            ''
              # override csp for built app requirements and maintain security headers
              header -Content-Security-Policy
              header +Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} cdn.jsdelivr.net unpkg.com *.posthog.com *.googletagmanager.com *.google-analytics.com analytics.plumj.am; object-src 'self' ${domain} *.${domain}; base-uri 'self'; frame-ancestors 'self'; form-action 'self' ${domain} *.${domain}; font-src 'self' ${domain} *.${domain} cdn.jsdelivr.net; connect-src 'self' ${domain} *.${domain} unpkg.com *.posthog.com *.googletagmanager.com *.google-analytics.com analytics.plumj.am; img-src 'self' ${domain} *.${domain} unpkg.com *.tile.openstreetmap.org www.googletagmanager.com data:;"
              header -X-Frame-Options
              header +X-Frame-Options DENY
              header -X-Content-Type-Options
              header +X-Content-Type-Options nosniff
              header -X-XSS-Protection
              header +X-XSS-Protection "1; mode=block"
              header -Permissions-Policy
              header +Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()"
              header -Referrer-Policy
              header +Referrer-Policy strict-origin-when-cross-origin
            '';
        };
      };
    };
}
