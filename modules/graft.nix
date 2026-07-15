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
            checks_api_enabled = true;
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

            fff-hx = {
              display_name = "fff.hx";
              forge = "forgejo";
              clone_uri = "https://git.plumj.am/plumjam/fff.hx";
              flake_ref = ".#checks";
              systems = [ "x86_64-linux" ];
              build_timeout_secs = 3600;
              poll_interval_secs = 30;
              users = [ "plumjam" ];
              forgejo_url = "https://git.plumj.am";
              forgejo_repo_owner = "plumjam";
              forgejo_repo_name = "fff.hx";
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
            cache_entry_max_age_days = 14;
            verify_caches = [
              "s3://plumjam/nix?endpoint=fsn1.your-objectstorage.com&profile=plumjam-fsn1"
              "s3://nix?endpoint=sloe.taild29fec.ts.net:8015&profile=plumjam-garage&region=garage"
              "http://date.taild29fec.ts.net:5000"
              "http://kiwi.taild29fec.ts.net:5000"
              "http://plum.taild29fec.ts.net:5000"
              "http://yuzu.taild29fec.ts.net:5000"
              "http://sloe.taild29fec.ts.net:5000"
            ];
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
        # The cache probe (nix path-info --store) runs as graft-sentinel and
        # needs AWS creds to read the S3 binary caches. Point nix at a
        # credentials file we materialize from the sops secrets at start.
        environment.AWS_SHARED_CREDENTIALS_FILE = "${config.services.graft-sentinel.state_dir}/.aws/credentials";
        serviceConfig = {
          BindReadOnlyPaths = [ config.sops.secrets."graft-ssh".path ];
          LoadCredential = [
            "s3-plumjam-fsn1-access-key:${config.sops.secrets."s3/fsn1/access-key".path}"
            "s3-plumjam-fsn1-secret-key:${config.sops.secrets."s3/fsn1/secret-key".path}"
            "s3-plumjam-garage-access-key:${config.sops.secrets."s3/garage/access-key".path}"
            "s3-plumjam-garage-secret-key:${config.sops.secrets."s3/garage/secret-key".path}"
          ];
          ExecStartPre =
            let
              creds = pkgs.writeShellScript "graft-sentinel-aws-creds" ''
                set -eu
                mkdir -p ${config.services.graft-sentinel.state_dir}/.aws
                umask 077
                cat > ${config.services.graft-sentinel.state_dir}/.aws/credentials <<EOF
                [plumjam-fsn1]
                aws_access_key_id=$(cat "$CREDENTIALS_DIRECTORY/s3-plumjam-fsn1-access-key")
                aws_secret_access_key=$(cat "$CREDENTIALS_DIRECTORY/s3-plumjam-fsn1-secret-key")
                [plumjam-garage]
                aws_access_key_id=$(cat "$CREDENTIALS_DIRECTORY/s3-plumjam-garage-access-key")
                aws_secret_access_key=$(cat "$CREDENTIALS_DIRECTORY/s3-plumjam-garage-secret-key")
                region=garage
                EOF
                chown graft-sentinel:graft ${config.services.graft-sentinel.state_dir}/.aws/credentials
              '';
            in
            "+${creds}";
        };
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
