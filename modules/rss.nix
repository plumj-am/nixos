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

  flake.modules.common.rss-tui =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.age) secrets;
    in
    {
      hjem.extraModule = {
        packages = singleton pkgs.newsboat;

        xdg.config.files."newsboat/config".text = ''
          urls-source "freshrss"
          freshrss-url "https://rss.plumj.am/api/greader.php"
          freshrss-login "plumjam"
          freshrss-passwordfile "${secrets.rssApiPassword.path}"
        '';
      };
    };
}
