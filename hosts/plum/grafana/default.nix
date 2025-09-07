{ self, config, lib, ... }: let
  inherit (config.networking) domain;
  inherit (lib) const enabled genAttrs merge;

  fqdn = "metrics.${domain}";
  port = 8000;
in {
  imports = [
    (self + /modules/nginx.nix)
  ];

  age.secrets.grafanaPassword = {
    file = ./password.age;
    owner = "grafana";
  };

  systemd.services.grafana = {
    after = [ "network.target" ];
    requires = [ "network.target" ];
  };

  services.grafana = enabled {
    provision = enabled;

    settings = {
      analytics.reporting_enabled = false;

      database.type = "sqlite3";

      server.domain = fqdn;
      server.http_addr = "::1";
      server.http_port = port;

      users.default_theme = "system";
    };

    settings.security = {
      admin_email = "metrics@${domain}";
      admin_password = "$__file{${config.age.secrets.grafanaPassword.path}}";
      admin_user = "admin";

      cookie_secure = true;
      disable_gravatar = true;
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      extraConfig = /* nginx */ ''
        # grafana sets `nosniff` without correct content type so unset the header
        proxy_hide_header X-Content-Type-Options;
      '';

      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
    };
  };
}
