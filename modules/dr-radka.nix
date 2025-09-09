{ self, config, lib, pkgs, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled merge;

  app_port = 3000;
  app_user = "dr-radka";
  app_group = "dr-radka";
  app_dir = "/var/lib/dr-radka";
  build_dir = "${app_dir}/build";
in {
  imports = [(self + /modules/nginx.nix)];

  age.secrets.dr-radka-environment = {
    file = ../hosts/kiwi/dr-radka-environment.age;
    owner = app_user;
    group = app_group;
  };

  users.users.${app_user} = {
    isSystemUser = true;
    group = app_group;
    home = app_dir;
    createHome = true;
  };

  users.groups.${app_group} = {};

  systemd.services.dr-radka = {
    description = "Dr. Radka SvelteKit Application";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = app_user;
      Group = app_group;
      WorkingDirectory = build_dir;
      ExecStart = "${pkgs.bun}/bin/bun run ./index.js";
      Restart = "always";
      RestartSec = 5;
      EnvironmentFile = config.age.secrets.dr-radka-environment.path;

      # hardening
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ app_dir ];
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
    };

    environment = {
      NODE_ENV = "production";
      PORT = toString app_port;
      HOST = "127.0.0.1";
      ORIGIN = "https://${domain}";
    };
    path = with pkgs; [ bun ];
  };

  services.nginx = enabled {
    virtualHosts.${domain} = merge config.services.nginx.sslTemplate {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString app_port}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_cache_bypass $http_upgrade;

          # override csp for built app requirements and maintain security headers
          proxy_hide_header Content-Security-Policy;
          add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} cdn.jsdelivr.net unpkg.com *.posthog.com *.sanity.io *.googletagmanager.com *.google-analytics.com; object-src 'self' ${domain} *.${domain}; base-uri 'self'; frame-ancestors 'self'; form-action 'self' ${domain} *.${domain}; font-src 'self' ${domain} *.${domain} cdn.jsdelivr.net; connect-src 'self' ${domain} *.${domain} unpkg.com *.posthog.com *.sanity.io *.googletagmanager.com *.google-analytics.com; img-src 'self' ${domain} *.${domain} unpkg.com *.tile.openstreetmap.org *.sanity.io cdn.sanity.io googletagmanager.com data:;" always;
          add_header X-Frame-Options DENY always;
          add_header X-Content-Type-Options nosniff always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=()" always;
          add_header Referrer-Policy no-referrer always;
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    nodejs_22
    bun
  ];
}
