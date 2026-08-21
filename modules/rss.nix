{
  flake.modules.nixos.freshrss-server =
    { lib', config, ... }:
    let
      inherit (lib') merge;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      fqdn = "rss.${domain}";
    in
    {
      sops.secrets."rss-server/admin-password" = {
        sopsFile = ../secrets/services/rss.yaml;
        owner = "freshrss";
        mode = "400";
      };

      services.freshrss = {
        enable = true;

        api.enable = true;

        database.type = "sqlite";

        virtualHost = fqdn;
        baseUrl = "https://${fqdn}";

        defaultUser = "admin";
        passwordFile = secrets."rss-server/admin-password".path;
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';
      };
    };
}
