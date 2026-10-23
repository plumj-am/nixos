{
  flake.modules.nixos.freshrss-server =
    { lib, config, ... }:
    let
      inherit (lib.constants) tailnet;
      inherit (config.networking) hostName;
      inherit (config.sops) secrets;

      tailnetFqdn = "${hostName}.${tailnet}";
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

        virtualHost = tailnetFqdn;
        baseUrl = "http://${tailnetFqdn}:8083";

        defaultUser = "admin";
        passwordFile = secrets."rss-server/admin-password".path;
      };

      # Tailnet only: bind all interfaces, but the firewall trusts only ts0
      # and this port is not in allowedTCPPorts.
      services.nginx.virtualHosts.${tailnetFqdn}.listen = [
        {
          addr = "0.0.0.0";
          port = 8083;
        }
        {
          addr = "[::]";
          port = 8083;
        }
      ];
    };
}
