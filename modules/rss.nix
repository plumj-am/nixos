{
  flake.modules.nixos.freshrss-server =
    { config, ... }:
    let
      inherit (config.networking) domain;
      inherit (config.myLib) merge;
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

  flake.modules.common.rss-tui =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.sops) secrets;
    in
    {
      sops.secrets."rss-client/api-password" = {
        sopsFile = ../secrets/services/rss.yaml;
        owner = "jam";
      };

      hjem.extraModule = {
        packages = singleton pkgs.newsboat;

        xdg.config.files."newsboat/config".text = ''
          urls-source "freshrss"
          freshrss-url "https://rss.plumj.am/api/greader.php"
          freshrss-login "plumjam"
          freshrss-passwordfile "${secrets."rss-client/api-password".path}"
        '';
      };
    };
}
