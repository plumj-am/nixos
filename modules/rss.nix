{
  flake.modules.nixos.freshrss-server =
    { config, ... }:
    let
      inherit (config.networking) domain;
      inherit (config.myLib) merge;
      inherit (config.age) secrets;

      fqdn = "rss.${domain}";
    in
    {
      services.freshrss = {
        enable = true;

        api.enable = true;

        database.type = "sqlite";

        virtualHost = fqdn;
        baseUrl = "https://${fqdn}";

        defaultUser = "admin";
        passwordFile = secrets.rssAdminPassword.path;
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';
      };
    };
