{ self, ... }:
{
  flake.modules.nixos.default.imports = [
    self.modules.nixos.s3
    self.modules.nixos.s3-upload
  ];

  flake.modules.nixos.s3 =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.constants) tailnet;
      inherit (config.sops) secrets;

      caches = {
        garage = {
          alias = "plumjam-garage";
          bucket = "nix";
          endpoint = "sloe.${tailnet}:8015";
          region = "garage";
          pathStyle = "on";
          apiVersion = "s3v4";
        };
      };
    in
    {
      config = {
        s3 = {
          inherit caches;

          # Materialised by the `s3-credentials` systemd service from the four
          # sops secrets below; group-readable so every S3 consumer can share
          # one credentials file.
          credentialsFile = "/var/lib/s3/.aws/credentials";
        };

        users.groups.s3 = { };

        sops.secrets = {
          "s3/garage/access-key".sopsFile = ../secrets/all/s3.yaml;
          "s3/garage/secret-key".sopsFile = ../secrets/all/s3.yaml;
        };

        # One-time systemd service: reads the two sops-rendered secret files
        # via $CREDENTIALS_DIRECTORY and writes an AWS credentials
        # file readable by the `s3` group.
        systemd.services.s3-credentials = {
          description = "Materialise shared AWS credentials for S3 consumers";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            StateDirectory = "s3";
            StateDirectoryMode = "0755";
            LoadCredential = [
              "s3-garage-access-key:${secrets."s3/garage/access-key".path}"
              "s3-garage-secret-key:${secrets."s3/garage/secret-key".path}"
            ];
            ExecStart =
              let
                creds = pkgs.writeShellScript "s3-aws-creds" ''
                  set -eu
                  mkdir -p /var/lib/s3/.aws
                  umask 077
                  cat > /var/lib/s3/.aws/credentials <<EOF
                  [${caches.garage.alias}]
                  aws_access_key_id=$(cat "$CREDENTIALS_DIRECTORY/s3-garage-access-key")
                  aws_secret_access_key=$(cat "$CREDENTIALS_DIRECTORY/s3-garage-secret-key")
                  region=${caches.garage.region}
                  EOF
                  chown root:s3 /var/lib/s3/.aws/credentials
                  chmod 0640 /var/lib/s3/.aws/credentials
                '';
              in
              "+${creds}";
          };
        };
      };
    };

  flake.modules.nixos.s3-upload =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (config.s3.caches) garage;
      inherit (config.sops) secrets;

      s3SharedArgs = "&priority=43&multipart-upload=true&multipart-threshold=50M&multipart-chunk-size=10M";

      garageAlias = garage.alias;
      garageBucket = garage.bucket;
      garageEndpoint = garage.endpoint;
      garageRegion = garage.region;
      garagePathStyle = garage.pathStyle;
      garageApiVersion = garage.apiVersion;
      garageS3Cache = "s3://${garageBucket}?endpoint=http://${garageEndpoint}&profile=${garageAlias}&region=${garageRegion}${s3SharedArgs}";

      setupAwsCreds = pkgs.writeShellScriptBin "setup-aws-creds" ''
        #!/usr/bin/env bash
        set -euo pipefail

        dir=$1
        user=$2
        group=$3
        mkdir -p "$dir"

        garageAccessKey=$(cat ${secrets."s3/garage/access-key".path})
        garageSecretKey=$(cat ${secrets."s3/garage/secret-key".path})

        cat > "$dir/credentials" <<EOF
        [${garageAlias}]
        aws_access_key_id=$garageAccessKey
        aws_secret_access_key=$garageSecretKey
        region=${garageRegion}
        EOF
        chmod 600 "$dir/credentials"
        chown $user:$group "$dir/credentials"
      '';

      setupMc = pkgs.writeShellScriptBin "setup-mc" ''
        #!/usr/bin/env bash
        set -euo pipefail

        config_dir=$1
        export MC_CONFIG_DIR="$config_dir"
        mkdir -p "$config_dir"

        ${getExe pkgs.minio-client} --quiet alias set ${garageAlias} \
          http://${garageEndpoint} \
          "$(cat ${secrets."s3/garage/access-key".path})" \
          "$(cat ${secrets."s3/garage/secret-key".path})" \
          --api ${garageApiVersion} \
          --path ${garagePathStyle}

        if ! ${getExe pkgs.minio-client} --quiet ilm ls --json ${garageAlias}/${garageBucket} | ${getExe pkgs.jq} -e '.config.Rules[]? | select(.Expiration.Days == 14)'; then
          ${getExe pkgs.minio-client} --quiet ilm add --expire-days 14 ${garageAlias}/${garageBucket} 2>/dev/null || true
        fi
      '';

      setupScript = pkgs.writeShellScriptBin "s3-setup" ''
                #!/usr/bin/env bash
                set -eu

                # jam
                ${getExe setupAwsCreds} ${config.users.users.jam.home}/.aws jam users
                ${getExe setupMc} ${config.users.users.jam.home}/.mc
                chown -R jam:users ${config.users.users.jam.home}/.mc

                # root
                ${getExe setupAwsCreds} /root/.aws root root
                ${getExe setupMc} /root/.mc

                nix_cache_info=$(mktemp)
                cat > "$nix_cache_info" << EOF
        StoreDir: /nix/store
        WantMassQuery: 1
        Priority: 43
        EOF

                # garage-bootstrap.service orders after garage.service but
                # the daemon takes minutes to bind :8015 after its unit
                # starts; `After=` orders unit start, not readiness. Wait
                # for the S3 API to answer before uploading. Garage
                # replies 403 to an anonymous GET, so any HTTP status
                # (not a connection error) means it is listening.
                for _ in $(seq 1 60); do
                  if ${getExe pkgs.curl} -sS --max-time 2 \
                    -o /dev/null "http://${garageEndpoint}/"; then
                    break
                  fi
                  sleep 1
                done

                MC_CONFIG_DIR=/root/.mc \
                ${getExe pkgs.minio-client} cp --quiet "$nix_cache_info" ${garageAlias}/${garageBucket}/nix-cache-info

                rm "$nix_cache_info"

                echo "S3 setup complete."
                echo "  Garage Bucket: ${garageAlias}"
                echo "  Garage Endpoint: ${garageEndpoint}"
                echo "  Garage Substituter: ${garageS3Cache}"
      '';
    in
    {
      environment.systemPackages = [
        pkgs.minio-client
        setupAwsCreds
        setupMc
        setupScript
      ];

      systemd.tmpfiles.rules = [
        "d ${config.users.users.jam.home}/.mc 0755 jam users -"
        "d /root/.mc 0755 root root -"
        "d ${config.users.users.jam.home}/.aws 0700 jam users -"
        "d /root/.aws 0700 root root -"
      ];

      systemd.services.s3-setup = {
        description = "S3 credential & cache setup";
        # Only sloe runs the garage daemon; on other hosts
        # garage-bootstrap.service does not exist, so the
        # After/Wants would reference a missing unit and
        # fail to activate. The readiness retry in the
        # script already handles a slow garage start.
        after = [ "network.target" "sops.service" ]
          ++ lib.optionals config.services.garage.enable [
            "garage-bootstrap.service"
          ];
        wants = lib.optionals config.services.garage.enable [
          "garage-bootstrap.service"
        ];
        wantedBy = [ "multi-user.target" ];

        # mc needs glibc.getent
        path = [
          pkgs.glibc.getent
          pkgs.minio-client
          pkgs.uutils-coreutils-noprefix
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = getExe setupScript;
        };
      };

      nix.settings = {
        extra-substituters = [
          garageS3Cache
        ];

        extra-trusted-public-keys = [
          "yuzu-store.plumj.am:rRhcZfgv1nSDQxDhgzaudcpyl/JtqoEf4QOsPble7S8="
          "plum-store.plumj.am:LBmfncp/ftlagUEZOM0NWK2tTH4fIT0Bk2WEBU48CNM="
          "kiwi-store.plumj.am:PMlO9Tv8jZf5huFRsKWBD7ejVASjUXnZS1o7xpsN5hw="
          "sloe-store.plumj.am:1qIquG/lWLGgyeyfFBSNuifrNevsGXFf53Bi0stcsxo="
          "date-store.plumj.am:1sziS/y3AiWPV8TY8pHtK3tYxiN10ujutWDNpo4O1Fg="
          # TODO ?lime-store?
          "blackwell-store.plumj.am:YmTvW2JngBUxfgWoKHJzxKu7Xhxt4VzK5u3D0Chudn4="
        ];

        secret-key-files = secrets.nix-store-key.path;
      };
    };
}
