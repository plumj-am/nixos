{ inputs, ... }:
{
  flake.modules.nixos.buildbot-master =
    {
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib') merge;
      inherit (config.networking) domain hostName;
      inherit (config.age) secrets;

      buildbot-nix-patched =
        let
          orig = config.services.buildbot-nix.packages.python.pkgs.callPackage (
            inputs.buildbot-nix + "/packages/buildbot-nix.nix"
          ) { buildbot-gitea = config.services.buildbot-nix.packages.buildbot-gitea; };
        in
        orig.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/buildbot-nix-gcroot-warning.patch
            ./patches/buildbot-nix-no-cancel.patch
          ];
          postPatch = (old.postPatch or "") + ''
            substituteInPlace buildbot_nix/nix_build.py \
              --replace-fail \
                '"--accept-flake-config",' '
                "--accept-flake-config",
                "--builders", "",
                "--fallback",
              '
          '';
        });
    in
    {
      imports = singleton inputs.buildbot-nix.nixosModules.buildbot-master;

      assertions = singleton {
        assertion = hostName == "plum";
        message = "The buildbot-master module should only be used on the 'plum' host.";
      };

      age.secrets = {
        buildbotAccessToken.rekeyFile = ../secrets/buildbot-access-token.age;
        buildbotWebhookSecret.rekeyFile = ../secrets/buildbot-webhook-secret.age;
        buildbotOauthSecret.rekeyFile = ../secrets/buildbot-oauth-secret.age;
        buildbotWorkersFile.rekeyFile = ../secrets/buildbot-workers-file.age;
        buildbotHttpBasicAuthPassword.rekeyFile = ../secrets/buildbot-http-basic-auth-password.age;
        buildbotCookieSecret.rekeyFile = ../secrets/buildbot-cookie-secret.age;
      };

      services.buildbot-nix.packages.buildbot-nix = buildbot-nix-patched;

      services.buildbot-nix.master = {
        enable = true;

        domain = "buildbot.${domain}";
        admins = singleton "PlumJam";

        workersFile = secrets.buildbotWorkersFile.path;
        httpBasicAuthPasswordFile = secrets.buildbotHttpBasicAuthPassword.path;

        gitea = {
          enable = true;

          instanceUrl = "https://git.${domain}";
          topic = null;

          oauthId = "26db7117-c7ec-4bc9-b273-7b12bb0f83aa";
          oauthSecretFile = secrets.buildbotOauthSecret.path;
          tokenFile = secrets.buildbotAccessToken.path;
          webhookSecretFile = secrets.buildbotWebhookSecret.path;
        };

        accessMode.fullyPrivate = {
          backend = "gitea";

          clientId = "26db7117-c7ec-4bc9-b273-7b12bb0f83aa";
          clientSecretFile = secrets.buildbotOauthSecret.path;
          cookieSecretFile = secrets.buildbotCookieSecret.path;
        };

        branches = {
          mergeQueue.matchGlob = "gitea-mq/*";
        };
      };

      services.buildbot-master.extraConfig = # python
        ''
          c["protocols"] = {"pb": {"port": "tcp:9989:interface=\\:\\:"}}

          c['www']['ui_default_config'] = {
            'Home.sidebar_menu_groups_expand_behavior': "Always expand",
            'Builders.show_workers_name': True,
          }
        '';

      networking.firewall.allowedTCPPorts = singleton 9989;

      # Override default GitHub scopes which are incompatible with Forgejo.
      systemd.services.oauth2-proxy.environment = {
        OAUTH2_PROXY_SCOPE = "read:user read:organization";
      };

      services.nginx.virtualHosts."buildbot.${domain}" = merge config.services.nginx.sslTemplate { };
    };

  flake.modules.nixos.buildbot-worker =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.networking) hostName;
      inherit (config.age) secrets;
    in
    {
      imports = singleton inputs.buildbot-nix.nixosModules.buildbot-worker;

      age.secrets = {
        buildbotMasterPassword.rekeyFile = ../secrets/buildbot-master-password.age;
      };

      nix.settings.trusted-users = singleton "buildbot-worker";

      services.buildbot-nix.worker = {
        enable = true;

        masterUrl =
          if hostName == "plum" then "tcp:host=localhost:port=9989" else "tcp:host=plum:port=9989";

        workerPasswordFile = secrets.buildbotMasterPassword.path;
      };
    };
}
