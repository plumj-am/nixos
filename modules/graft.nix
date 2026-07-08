let
  localGrpcHost = "0.0.0.0";
  mainHost = "sloe";
  sentinelHost = "${mainHost}.taild29fec.ts.net";

  sentinelHttpPort = 8019;
  sentinelGrpcPort = 8020;

  nixExtraArgs = [
    "--accept-flake-config"
    "--builders"
    ""
    "--cores"
    "1"
    "--max-jobs"
    "1"
    "--fallback"
  ];
in
{
  flake.modules.nixos.graft-sentinel =
    {
      inputs,
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib') merge;
      inherit (config.networking) domain hostName;
      inherit (config.sops) secrets;
    in
    {
      imports = singleton inputs.grove.nixosModules.graft-sentinel;

      sops.secrets.graft-environment.sopsFile = ../secrets/services/graft.yaml;

      sops.secrets."graft-ssh" = {
        sopsFile = ../secrets/${hostName}/graft-ssh.yaml;
        group = "graft";
        mode = "0440";
      };

      services.graft-sentinel = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.graft-graft-sentinel;

        state_dir = "/var/lib/graft-sentinel";

        environment_file = secrets.graft-environment.path;

        config = {
          http = {
            host = localGrpcHost;
            port = sentinelHttpPort;
            dashboard_url = "https://graft.plumj.am";
          };

          grpc = {
            host = localGrpcHost;
            port = sentinelGrpcPort;
          };

          database.path = "ci.db";

          projects = {
            nixos = {
              display_name = "NixOS";
              forge = "forgejo";
              clone_uri = "https://git.plumj.am/plumjam/nixos";
              flake_ref = ".#checks";
              systems = [ "x86_64-linux" ];
              build_timeout_secs = 3600;
              poll_interval_secs = 30;
              users = [ "plumjam" ];
              forgejo_url = "https://git.plumj.am";
              forgejo_repo_owner = "plumjam";
              forgejo_repo_name = "nixos";
            };

            grove = {
              display_name = "Grove";
              forge = "gerrit";
              clone_uri = "https://gerrit.plumj.am/grove";
              flake_ref = ".#checks";
              systems = [ "x86_64-linux" ];
              build_timeout_secs = 3600;
              poll_interval_secs = 30;
              users = [
                "plumjam"
                "antteheatta"
              ];
              gerrit_url = "https://gerrit.plumj.am";
              gerrit_username = "graft";
              gerrit_sub_projects = singleton {
                name = "grove";
                branch = "master";
              };
            };
          };

          oauth = {
            provider = "forgejo";
            allowed_users = [
              "plumjam"
              "antteheatta"
            ];
            forgejo = {
              client_id = "78af9c96-2e61-4ab8-a3fd-5834020e6c73";
              auth_url = "https://git.plumj.am/login/oauth/authorize";
              token_url = "https://git.plumj.am/login/oauth/access_token";
              redirect_url = "https://graft.plumj.am/auth/callback";
            };
          };

          nix = {
            bin = pkgs.nix;
            extra_args = nixExtraArgs;
          };

          nodes = {
            heartbeat_timeout_secs = 60;
            max_retries = 3;
          };
        };
      };

      # Old subdomain to avoid breaking links.
      services.nginx.virtualHosts."gerrix.${domain}" = merge config.services.nginx.sslTemplate {
        locations."/".return = "https://graft.plumj.am$request_uri";

      };

      services.nginx.virtualHosts."graft.${domain}" = merge config.services.nginx.sslTemplate {
        locations."/".proxyPass = "http://127.0.0.1:${toString sentinelHttpPort}";
      };

      systemd.services.graft-sentinel = {
        environment.GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -i ${
          config.sops.secrets."graft-ssh".path
        } -o StrictHostKeyChecking=accept-new";
        serviceConfig.BindReadOnlyPaths = [ config.sops.secrets."graft-ssh".path ];
      };
    };

  flake.modules.nixos.graft-node =
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
      inherit (config) systemInfo;
    in
    {
      imports = singleton inputs.grove.nixosModules.graft-node;

      sops.secrets."graft-ssh" = {
        sopsFile = ../secrets/${hostName}/graft-ssh.yaml;
        group = "graft";
        mode = "0440";
      };

      services.graft-node = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.graft-graft-node;

        state_dir = "/var/lib/graft-node";

        config = {
          sentinel = {
            addr = "http://${sentinelHost}:${toString sentinelGrpcPort}";
            node_name = hostName;
          };

          builder = {
            # Leave 1 core for free evaluation on sentinel host.
            max_concurrent =
              if hostName == mainHost then
                systemInfo.cores - 1
              else if hostName == "yuzu" then
                12
              else
                systemInfo.cores;
            build_timeout_secs = 3600;
            work_dir = "/tmp/graft-node/builds";
          };

          nix = {
            bin = pkgs.nix;
            extra_args = nixExtraArgs;
          };

          scheduler = {
            quiet_hours_start =
              if hostName == "date" then
                "23:15"
              else if hostName == "sloe" then
                "02:30"
              else
                "";
            quiet_hours_end = "10:00";
          };
        };
      };

      systemd.services.graft-node = {
        environment.GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -i ${
          config.sops.secrets."graft-ssh".path
        } -o StrictHostKeyChecking=accept-new";
      };
    };
}
