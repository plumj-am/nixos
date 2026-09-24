let
  workflowPackages =
    { inputs, pkgs }:
    [
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
      pkgs.docker
      pkgs.docker-compose
      pkgs.forgejo-cli
      pkgs.gcc
      pkgs.gitMinimal
      pkgs.gzip
      pkgs.jq
      pkgs.just
      pkgs.nix
      pkgs.nix-fast-build
      pkgs.nodejs
      pkgs.nushell
      pkgs.opencode
      pkgs.openssl
      pkgs.pkg-config
      pkgs.ripgrep
      pkgs.sccache
      pkgs.sqlx-cli
      pkgs.uutils-tar
      pkgs.which
      pkgs.xz
    ];

  runnerHost =
    { lib, config, ... }:
    {
      virtualisation.docker.enable = true;

      systemd.services.docker-network-prune = {
        startAt = "daily";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe config.virtualisation.docker.package} network prune --force";
        };
      };
    };
in
{
  flake.modules.nixos.forgejo-runner =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.networking) hostName;
    in
    {
      imports = singleton runnerHost;

      sops.secrets."forgejo-runner/token".sopsFile = ../secrets/services/forgejo.yaml;

      users = {
        users.gitea-runner = {
          description = "gitea-runner";
          isSystemUser = true;
          group = "gitea-runner";
        };
        groups.gitea-runner = { };
      };

      services.gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances.${hostName} = {
          enable = true;
          name = hostName;
          url = "https://git.plumj.am";
          tokenFile = config.sops.secrets."forgejo-runner/token".path;
          labels = [
            "self-hosted:host"
            "${hostName}:host"
            "grove-systems:host"
            "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest"
          ];
          settings.runner = {
            timeout = "6h";
            cache.enabled = true;
          };
          hostPackages = workflowPackages { inherit inputs pkgs; };
        };
      };
    };

  flake.modules.nixos.github-runner =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.networking) hostName;
    in
    {
      imports = singleton runnerHost;

      sops.secrets."github-runner/token".sopsFile = ../secrets/services/github-runner.yaml;

      services.github-runners.${hostName} = {
        enable = true;
        name = hostName;
        url = "https://github.com/grove-systems/grove";
        tokenFile = config.sops.secrets."github-runner/token".path;
        replace = true;
        ephemeral = false;
        extraLabels = [
          hostName
          "grove-systems"
          "nixos"
        ];
        extraPackages = workflowPackages { inherit inputs pkgs; };
        serviceOverrides.SupplementaryGroups = singleton "docker";
      };
    };
}
