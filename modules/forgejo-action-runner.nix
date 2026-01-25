{
  flake.modules.nixos.forgejo-action-runner =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      inherit (lib.types) types;
      inherit (lib.options) mkOption;
      inherit (lib.modules) mkIf;

      hostName = config.networking.hostName;
    in
    {
      options.forgejo-action-runner = {
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

        capacity = mkOption {
          type = types.int;
          default = 1;
          description = "How many jobs this runner can handle concurrently";
        };
      };

      config = {
        users.groups.gitea-runner = { };

        users.users.gitea-runner = {
          description = "gitea-runner";
          isSystemUser = true;
          group = "gitea-runner";
        };

        services.gitea-actions-runner = {
          package = pkgs.forgejo-runner;
          instances.${hostName} = {
            enable = true;
            name = hostName;
            tokenFile = config.age.secrets.forgejoRunnerToken.path;
            inherit (config.forgejo-action-runner) url labels;

            settings = {
              inherit (config.forgejo-action-runner) capacity;
              timeout = "6h";
              cache.enabled = true;
            };

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

              pkgs.bash
              pkgs.claude-code
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
              pkgs.openssl
              pkgs.opencode
              pkgs.pkg-config
              pkgs.ripgrep
              pkgs.sccache
              pkgs.sqlx-cli
              pkgs.which
              pkgs.xz
            ]
            ++ lib.optionals config.forgejo-action-runner.withDocker [
              pkgs.docker
              pkgs.docker-compose
            ]
            ++ config.forgejo-action-runner.extraHostPackages;
          };
        };
        virtualisation.docker.enable = mkIf config.forgejo-action-runner.withDocker true;
      };
    };
}
