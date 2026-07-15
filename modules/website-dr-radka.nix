{
  flake.modules.nixos.website-dr-radka =
    {
      config,
      pkgs,
      lib,
      inputs,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;
      inherit (config.myLib) merge;

      radka = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.radka;

      app_port = 3000;
      app_user = "dr-radka";
      app_group = "dr-radka";
      app_dir = "/var/lib/dr-radka";
    in
    {
      sops.secrets."radka/environment" = {
        sopsFile = ../secrets/services/radka.yaml;
        owner = "dr-radka";
        group = "dr-radka";
      };

      users.users.${app_user} = {
        isSystemUser = true;
        group = app_group;
        home = app_dir;
        createHome = true;
      };

      users.groups.${app_group} = { };

      systemd.services.dr-radka = {
        description = "Dr. Radka SvelteKit Application";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = app_user;
          Group = app_group;
          WorkingDirectory = "${radka}";
          ExecStart = "${getExe pkgs.nodejs-slim_24} ${radka}/index.js";
          Restart = "always";
          RestartSec = 5;
          EnvironmentFile = secrets."radka/environment".path;

          # hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
        };

        environment = {
          NODE_ENV = "production";
          ORIGIN = "https://${domain}";
        };
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
            proxyPass = "http://0.0.0.0:${toString app_port}";
            extraConfig = # nginx
              ''
                # override csp for built app requirements and maintain security headers
                proxy_hide_header Content-Security-Policy;
                add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} cdn.jsdelivr.net unpkg.com *.posthog.com *.googletagmanager.com *.google-analytics.com analytics.plumj.am; object-src 'self' ${domain} *.${domain}; base-uri 'self'; frame-ancestors 'self'; form-action 'self' ${domain} *.${domain}; font-src 'self' ${domain} *.${domain} cdn.jsdelivr.net; connect-src 'self' ${domain} *.${domain} unpkg.com *.posthog.com *.googletagmanager.com *.google-analytics.com analytics.plumj.am; img-src 'self' ${domain} *.${domain} unpkg.com *.tile.openstreetmap.org www.googletagmanager.com data:;" always;
                add_header X-Frame-Options DENY always;
                add_header X-Content-Type-Options nosniff always;
                add_header X-XSS-Protection "1; mode=block" always;
                add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
                add_header Referrer-Policy no-referrer always;
              '';
          };
        };
      };

      environment.systemPackages = [ pkgs.nodejs-slim_24 ];
    };
}
