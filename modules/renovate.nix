{
  flake.modules.nixos.renovate =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) mkForce;
      inherit (config.age) secrets;
    in
    {
      age.secrets = {
        renovateBotToken = {
          rekeyFile = ../secrets/renovate-bot-token.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
        renovateGitHubToken = {
          rekeyFile = ../secrets/renovate-github-token.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
        renovateSigningKey = {
          rekeyFile = ../secrets/renovate-signing-key.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
        renovateSigningKeyPub = {
          rekeyFile = ../secrets/renovate-signing-key-pub.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
        renovateGerritHttpPassword = {
          rekeyFile = ../secrets/renovate-gerrit-http-password.age;
          owner = "renovate";
          group = "renovate";
          mode = "600";
        };
      };

      users.users.renovate = {
        isSystemUser = true;
        group = "renovate";
      };
      users.groups.renovate = { };

      systemd.services.renovate.serviceConfig.DynamicUser = mkForce false;
      services.renovate = {
        enable = true;
        runtimePackages = [
          pkgs.cargo # I don't think it not being nightly matters here.
          pkgs.openssh # For ssh-keygen.
        ];
        schedule = "*:0/10";
        settings = {
          platform = "gerrit";
          endpoint = "https://gerrit.plumj.am";
          username = "renovate"; # For Gerrit ONLY otherwise let renovate determine automatically.
          autodiscover = true;
          autodiscoverFilter = [ "grove" ];
          onboardingPrTitle = "renovate: Configure";
          configFileNames = [ ".forgejo/renovate.json" ];
          productLinks = { };
        };

        credentials = {
          RENOVATE_TOKEN = secrets.renovateBotToken.path;
          RENOVATE_GITHUB_COM_TOKEN = secrets.renovateGitHubToken.path;
          RENOVATE_GIT_PRIVATE_KEY = secrets.renovateSigningKey.path;
          RENOVATE_PASSWORD = secrets.renovateGerritHttpPassword.path;
        };
      };
    };
}
