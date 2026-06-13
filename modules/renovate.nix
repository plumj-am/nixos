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
      inherit (lib.attrsets) genAttrs;
      inherit (lib.trivial) flip const;
      inherit (config.sops) secrets;
    in
    {
      sops.secrets =
        flip genAttrs
          (const {
            sopsFile = ../secrets/services/renovate.yaml;
            owner = "renovate";
            group = "renovate";
            mode = "600";
          })
          [
            "renovate/bot-token"
            "renovate/github-token"
            "renovate/signing-key"
            "renovate/signing-key-pub"
            "renovate/gerrit-http-password"
          ];

      users.users.renovate = {
        isSystemUser = true;
        group = "renovate";
      };
      users.groups.renovate = { };

      # How tf does this use 600M by default...
      systemd.services.renovate.serviceConfig = {
        DynamicUser = mkForce false;

        MemoryHigh = "128M";
        MemoryMax = "256M";
      };
      services.renovate = {
        enable = true;
        runtimePackages = [
          pkgs.cargo # I don't think it not being nightly matters here.
          pkgs.openssh # For ssh-keygen.
        ];
        schedule = "*:0/10";
        settings = {
          platform = "gerrit";
          endpoint = "http://plum.taild29fec.ts.net:8011";
          username = "renovate"; # For Gerrit ONLY otherwise let renovate determine automatically.
          autodiscover = true;
          autodiscoverFilter = [ "grove" ];
          onboardingPrTitle = "renovate: Configure";
          configFileNames = [ ".forgejo/renovate.json" ];
          productLinks = { };
        };

        credentials = {
          RENOVATE_TOKEN = secrets."renovate/bot-token".path;
          RENOVATE_GITHUB_COM_TOKEN = secrets."renovate/github-token".path;
          RENOVATE_GIT_PRIVATE_KEY = secrets."renovate/signing-key".path;
          RENOVATE_PASSWORD = secrets."renovate/gerrit-http-password".path;
        };
      };
    };
}
