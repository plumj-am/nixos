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
      inherit (lib.lists) optional singleton;
      inherit (config.networking) hostName;
      inherit (config.sops) secrets;

      name = hostName;
      url = "http://plum.taild29fec.ts.net:8001";
      defaultLabels = [
        "self-hosted:host"
        "${name}:host"
        "plumworks-infra:host"
        "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest"
      ];
    in
    {
      sops.secrets."forgejo-runner/token".sopsFile = ../secrets/services/forgejo.yaml;
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
          tokenFile = secrets."forgejo-runner/token".path;
          inherit name url;

          labels = defaultLabels ++ optional config.systemInfo.ciRunner.strong "strong:host";

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
            pkgs.curl
            pkgs.forgejo-cli
            pkgs.gcc
            pkgs.gitMinimal
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

      services.cron = {
        enable = true;
        systemCronJobs = singleton "0 0 * * *    root    docker network prune --force";
      };
    };
}
