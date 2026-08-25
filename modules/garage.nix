{
  flake.modules.nixos.garage =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) merge;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      fqdnS3 = "s3.${domain}";
      fqdnWebUI = "cdn.${domain}";
      portS3 = 8015;
      portWebUI = 8016;
      portRPC = 8017;

      garageCli = "${config.services.garage.package}/bin/garage";
      garageZone = "garage";
      garageCapacity = "1.25T";
      buckets = [
        "nix"
        "backups"
      ];

      # Idempotently converges the cluster: assigns this node a role, applies
      # the layout, imports the shared S3 key and creates the buckets.
      # zone or capacity changes after the first apply still need a
      # manual `garage layout assign` + `apply`; only initial state is covered.
      garageBootstrap = pkgs.writeShellScript "garage-bootstrap" ''
        set -euo pipefail

        for _ in $(seq 1 30); do
          if node_id="$(${garageCli} node id 2>/dev/null | cut -d@ -f1)" && [ -n "$node_id" ]; then
            break
          fi
          sleep 1
        done

        if [ -z "''${node_id:-}" ]; then
          echo "garage node id did not become available in time" >&2
          exit 1
        fi

        if ${garageCli} status | grep -q 'NO ROLE ASSIGNED'; then
          ${garageCli} layout assign -z ${garageZone} -c ${garageCapacity} "$node_id"

          current_version="$(${garageCli} layout show | sed -n 's/^Current cluster layout version: \([0-9][0-9]*\)$/\1/p')"
          if [ -n "$current_version" ]; then
            next_version=$((current_version + 1))
          else
            next_version=1
          fi

          ${garageCli} layout apply --version "$next_version"
        fi

        key_id="$(cat "''${CREDENTIALS_DIRECTORY}/s3-garage-access-key")"
        key_secret="$(cat "''${CREDENTIALS_DIRECTORY}/s3-garage-secret-key")"

        if ! ${garageCli} key info "$key_id" >/dev/null 2>&1; then
          ${garageCli} key import "$key_id" "$key_secret" -n plumjam-garage --yes
        fi

        for bucket in ${toString buckets}; do
          if ! ${garageCli} bucket info "$bucket" >/dev/null 2>&1; then
            ${garageCli} bucket create "$bucket"
          fi

          ${garageCli} bucket allow --read --write --owner "$bucket" --key "$key_id"
        done
      '';
    in
    {
      sops.secrets = {
        "garage/environment".sopsFile = ../secrets/services/garage.yaml;

        # Same key pair the `s3` module distributes to clients; imported into
        # garage by `garage-bootstrap.service` below.
        "s3/garage/access-key".sopsFile = ../secrets/all/s3.yaml;
        "s3/garage/secret-key".sopsFile = ../secrets/all/s3.yaml;
      };

      services.garage = {
        enable = true;
        package = pkgs.garage_2;

        environmentFile = secrets."garage/environment".path;

        settings = {
          data_dir = singleton {
            capacity = garageCapacity;
            path = "/var/lib/garage/data";
          };

          replication_factor = 1;
          consistency_mode = "consistent";

          metadata_fsync = true;
          data_fsync = true;

          rpc_bind_addr = "[::]:${toString portRPC}";

          s3_api = {
            s3_region = "garage";

            api_bind_addr = "[::]:${toString portS3}";
            root_domain = fqdnS3;
          };

          s3_web = {
            bind_addr = "[::]:${toString portWebUI}";
            root_domain = fqdnWebUI;
          };
        };
      };

      services.nginx.virtualHosts.${fqdnS3} = merge config.services.nginx.sslTemplate {
        extraConfig = # nginx
          ''
            client_max_body_size 5g;
          '';
        locations."/".proxyPass = "http://[::1]:${toString portS3}";
      };

      services.nginx.virtualHosts.${fqdnWebUI} = merge config.services.nginx.sslTemplate {
        locations."/".proxyPass = "http://[::1]:${toString portWebUI}";
      };

      systemd.services.garage-bootstrap = {
        after = [ "garage.service" ];
        requires = [ "garage.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          # Long timeout so the 30s node-id wait and layout convergence never
          # hit the default 90s kill.
          TimeoutStartSec = "10min";
          # RPC secret + admin token so the CLI can talk to this node.
          EnvironmentFile = secrets."garage/environment".path;
          LoadCredential = [
            "s3-garage-access-key:${secrets."s3/garage/access-key".path}"
            "s3-garage-secret-key:${secrets."s3/garage/secret-key".path}"
          ];
          ExecStart = garageBootstrap;
        };
      };
    };
}
