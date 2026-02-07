let
  forgejoActionRunner =
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
      inherit (config.networking) hostName;

      name = hostName;
      url = "https://git.plumj.am/";
      defaultLabels = [
        "self-hosted:host"
        "${name}:host"
        "docpad-infra:host"
        "ubuntu-22.04:docker://docker.gitea.com/runner-images:ubuntu-22.04"
      ];
    in
    {
      options.forgejo-action-runner = {
        strong = mkOption {
          type = types.bool;
          default = false;
          description = "If the system is powerful enough to handle heavier workloads";
        };
      };

      config = {
        users.users.gitea-runner = {
          description = "gitea-runner";
          isSystemUser = true;
          group = "gitea-runner";
        };

        users.groups.gitea-runner = { };

        services.gitea-actions-runner = {
          package = pkgs.forgejo-runner;
          instances.${name} = {
            enable = true;
            tokenFile = config.age.secrets.forgejoRunnerToken.path;
            inherit name url;

            labels = defaultLabels ++ lib.optionals config.forgejo-action-runner.strong [ "strong:host" ];

            settings = {
              runner = {
                timeout = "6h";
                cache.enabled = true;
              };
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
              pkgs.nix-fast-build
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
              pkgs.docker
              pkgs.docker-compose
            ];
          };
        };
        virtualisation.docker.enable = true;
      };
    };
in
{
  flake.modules.nixos.forgejo-action-runner = forgejoActionRunner;
}
