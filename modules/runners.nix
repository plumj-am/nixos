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

  # UUIDs of the registered runners, taken from each host's
  # `/var/lib/gitea-runner/<host>/.runner`. forgejo-runner 13 needs a
  # uuid/token pair per connection; the token is read from that file at
  # activation, the uuid has to be pinned here.
  runnerUuids = {
    date = "690bb48d-96d7-4d13-9923-2a09f220e3ad";
    plum = "5cbf19b2-8021-445e-8c72-466a7a947697";
    sloe = "9f88bda0-d509-4789-b915-88fadd1eca12";
  };

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
  flake.nixosModules.forgejo-runner =
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

      # `.runner` stays the source of truth for registration: the token is
      # copied into a systemd credential at activation instead of being
      # decrypted into the Nix store.
      system.activationScripts."forgejo-runner-token" = ''
        install -d -m 0700 /run/forgejo-runner
        if test -e /var/lib/gitea-runner/${hostName}/.runner; then
          ${lib.getExe pkgs.jq} -r .token /var/lib/gitea-runner/${hostName}/.runner \
            > /run/forgejo-runner/${hostName}-token
          chmod 0600 /run/forgejo-runner/${hostName}-token
        else
          echo "forgejo-runner: ${hostName} has no .runner; no token credential provisioned" >&2
        fi
      '';

      services.forgejo-runner = {
        package = pkgs.forgejo-runner;
        instances.${hostName} = {
          enable = true;
          settings = {
            server.connections.default = {
              url = "https://git.plumj.am";
              uuid =
                runnerUuids.${hostName}
                  or (throw "register a forgejo runner for ${hostName} and add its uuid to runnerUuids");
            };
            runner = {
              labels = [
                "self-hosted:host"
                "${hostName}:host"
                "grove-systems:host"
                "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest"
              ];
              timeout = "6h";
              cache.enabled = true;
            };
          };
          secrets.server.connections.default.token_url = "/run/forgejo-runner/${hostName}-token";
          hostPackages = workflowPackages { inherit inputs pkgs; };
        };
      };
    };

  flake.nixosModules.github-runner =
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
