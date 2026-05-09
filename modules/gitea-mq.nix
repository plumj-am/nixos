{
  flake.modules.nixos.gitea-mq =
    {
      inputs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib') merge;
      inherit (config.networking) domain;
      inherit (config.age) secrets;

      forgejoUrl = "git.${domain}";
      port = 8006;
    in
    {
      imports = singleton inputs.gitea-mq.nixosModules.default;

      # services.postgresql.ensure = singleton "gitea-mq"; # Until Forgejo is supported.

      age.secrets = {
        forgejoAccessToken.rekeyFile = ../secrets/forgejo-access-token.age;
        giteamqWebhookSecret.rekeyFile = ../secrets/gitea-mq-webhook-secret.age;
        giteamqHtpasswd = {
          rekeyFile = ../secrets/gitea-mq-htpasswd.age;
          owner = "nginx";
          group = "nginx";
          mode = "0400";
        };
      };

      services.gitea-mq = {
        enable = false; # Until Forgejo is supported.
        giteaUrl = "https://${forgejoUrl}";

        repos = [ "PlumWorks/grove" ];
        externalUrl = "https://mq.${domain}";
        listenAddr = "127.0.0.1:${toString port}";
        databaseUrl = "postgres:///gitea-mq?host=/run/postgresql";
        logLevel = "debug";
        hideRefFromClients = false;

        giteaTokenFile = secrets.forgejoAccessToken.path;
        webhookSecretFile = secrets.giteamqWebhookSecret.path;
      };

      services.nginx.virtualHosts."mq.${domain}" = merge config.services.nginx.sslTemplate {
        locations."/" = {
          # basicAuthFile = config.age.secrets.giteamqHtpasswd.path;
          proxyPass = "http://127.0.0.1:${toString port}";
        };
      };
    };
}
