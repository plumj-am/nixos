{ self, config, lib, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled mkOption;

  fqdn = "analytics.${domain}";
  port = 8007;
in {
  imports = [ (self + /modules/postgresql.nix) ];

  options.services.plausible.extraNginxConfigFor = mkOption {
    type    = lib.types.functionTo lib.types.str;
    default = domain: ''
      proxy_set_header Accept-Encoding "";
      sub_filter "</head>" '<script defer data-domain="${domain}" data-api="https://${fqdn}/api/event" src="https://${fqdn}/js/script.file-downloads.hash.outbound-links.js"></script><script>window.plausible = window.plausible || function() { (window.plausible.q = window.plausible.q || []).push(arguments) }</script></head>';
      sub_filter_last_modified on;
      sub_filter_once on;
    '';
  };

  config = {
    services.postgresql.ensure = [ "plausible" ];

    age.secrets.plausibleKey = {
      file  = ./key.age;
      owner = "plausible";
    };

    services.plausible = enabled {
      database = {
        clickhouse.setup = true;
        postgres.setup   = true;
      };

      server = {
        inherit port;
        disableRegistration = true;
        secretKeybaseFile   = config.age.secrets.plausibleKey.path;
        baseUrl             = "https://${fqdn}";
        listenAddress       = "::1";
      };
    };

    services.nginx.virtualHosts.${fqdn} = lib.merge config.services.nginx.sslTemplate {
      extraConfig = config.services.plausible.extraNginxConfigFor fqdn;

      locations."/" = {
        proxyPass       = "http://[::1]:${toString port}";
        proxyWebsockets = true;
      };
    };
  };
}
