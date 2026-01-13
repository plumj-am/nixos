{
  config.flake.modules.nixos.forgejo-action-runner =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      inherit (lib)
        mkIf
        mkOption
        types
        ;
    in
    {
      options.ci-runner = {
        enable = lib.mkEnableOption "forgejo CI runner";

        tokenFile = mkOption {
          type = types.path;
          description = "Path to the runner token file";
        };

        url = mkOption {
          type = types.str;
          default = "https://git.plumj.am/";
          description = "Forgejo instance URL";
        };

        labels = mkOption {
          type = types.listOf types.str;
          default = [ "self-hosted:host" ];
          description = "Runner labels";
        };

        extraHostPackages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages to add to the runner";
        };

        withDocker = mkOption {
          type = types.bool;
          default = false;
          description = "Include docker and docker-compose";
        };
      };

      config = mkIf config.ci-runner.enable {
        age.secrets.forgejoRunnerToken.rekeyFile = config.ci-runner.tokenFile;

        users.groups.gitea-runner = { };

        users.users.gitea-runner = {
          description = "gitea-runner";
          isSystemUser = true;
          group = "gitea-runner";
        };

        services.gitea-actions-runner = {
          package = pkgs.forgejo-runner;
          instances.${config.networking.hostName} = {
            enable = true;
            name = config.networking.hostName;
            tokenFile = config.age.secrets.forgejoRunnerToken.path;
            url = config.ci-runner.url;
            labels = config.ci-runner.labels;

            settings.cache.enabled = false;

            hostPackages = [
              (inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [
                "cargo"
                "clippy"
                "miri"
                "rustc"
                "rust-analyzer"
                "rustfmt"
                "rust-std"
                "rust-src"
              ])

              inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default

              pkgs.bash
              pkgs.curl
              pkgs.forgejo-cli
              pkgs.gcc
              pkgs.git
              pkgs.gnutar
              pkgs.gzip
              pkgs.just
              pkgs.jq
              pkgs.nix
              pkgs.nodejs
              pkgs.nushell
              pkgs.opencode
              pkgs.openssl
              pkgs.pkg-config
              pkgs.ripgrep
              pkgs.sqlx-cli
              pkgs.which
              pkgs.xz
            ]
            ++ lib.optionals config.ci-runner.withDocker [
              pkgs.docker
              pkgs.docker-compose
            ]
            ++ config.ci-runner.extraHostPackages;
          };
        };
      };
    };
}
