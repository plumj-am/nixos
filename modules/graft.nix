{
  flake.modules.nixos.graft =
    {
      inputs,
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton foldl';
      inherit (lib') merge;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      cfg = config.services.graft;

      remote_builders =
        let
          mkRemoteBuilder =
            {
              hostName,
              maxJobs,
              speedFactor,
              system,
              ...
            }:
            singleton {
              inherit
                hostName
                maxJobs
                speedFactor
                system
                ;
              protocol = "ssh-ng";
              sshUser = "build";
              sshKey = "/root/.ssh/id";
              supportedFeatures = [
                "auto-allocate-uids"
                "benchmark"
                "big-parallel"
                "ca-derivations"
                "cgroups"
                "kvm"
                "nixos-test"
                "uid-range"
              ];
            };
        in
        mkRemoteBuilder {
          hostName = "sloe";
          maxJobs = 12;
          speedFactor = 5;
          system = "x86_64-linux";
        }
        ++ mkRemoteBuilder {
          hostName = "date";
          maxJobs = 12;
          speedFactor = 4;
          system = "x86_64-linux";
        }
        ++ mkRemoteBuilder {
          hostName = "plum";
          maxJobs = 4;
          speedFactor = 3;
          system = "x86_64-linux";
        };
    in
    {
      imports = singleton inputs.grove.nixosModules.graft;

      sops.secrets.graft-environment.sopsFile = ../secrets/services/graft.yaml;

      sops.secrets."graft-ssh" = {
        sopsFile = ../secrets/services/graft-ssh.yaml;
        group = "graft";
        mode = "0440";
      };

      services.graft = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.graft;

        state_dir = "/var/lib/graft";

        environment_file = secrets.graft-environment.path;

        config = {
          http = {
            host = "127.0.0.1";
            port = 8019;
            dashboard_url = "https://graft.plumj.am";
            checks_api_enabled = true;
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

            grove_forgejo = {
              display_name = "Grove";
              forge = "forgejo";
              clone_uri = "https://git.plumj.am/grove-systems/grove";
              flake_ref = ".#checks";
              systems = [ "x86_64-linux" ];
              build_timeout_secs = 3600;
              poll_interval_secs = 30;
              users = [
                "plumjam"
                "antteheatta"
              ];
              forgejo_url = "https://git.plumj.am";
              forgejo_repo_owner = "grove-systems";
              forgejo_repo_name = "grove";
            };

            grove = {
              display_name = "Grove [Gerrit Archive]";
              forge = "gerrit";
              clone_uri = "https://gerrit.plumj.am/grove";
              flake_ref = ".#checks";
              systems = [ "x86_64-linux" ];
              build_timeout_secs = 3600;
              poll_interval_secs = 604800;
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
            extra_args = [
              "--accept-flake-config"
              "--fallback"
            ];
          };

          nodes.max_retries = 3;

          builder.max_concurrent = foldl' (acc: b: acc + b.maxJobs) 0 <| remote_builders;
        };

        inherit remote_builders;
      };
      # Old subdomain to avoid breaking links.
      services.nginx.virtualHosts."gerrix.${domain}" = merge config.services.nginx.sslTemplate {
        locations."/".return = "https://graft.plumj.am$request_uri";

      };

      services.nginx.virtualHosts."graft.${domain}" = merge config.services.nginx.sslTemplate {
        locations."/".proxyPass = "http://127.0.0.1:${toString cfg.config.http.port}";
      };

      systemd.services.graft = {
        environment.GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -i ${
          config.sops.secrets."graft-ssh".path
        } -o StrictHostKeyChecking=accept-new";
        # The cache probe (nix path-info --store) runs as graft and
        # needs AWS creds to read the S3 binary caches. The shared file is
        # materialised by the `s3` aspect (s3-credentials.service).
        environment.AWS_SHARED_CREDENTIALS_FILE = config.s3.credentialsFile;
        serviceConfig = {
          BindReadOnlyPaths = [ config.sops.secrets."graft-ssh".path ];
          SupplementaryGroups = [
            "graft"
            "s3"
          ];
        };
      };
    };

}
