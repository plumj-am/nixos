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

        # One-time systemd service: reads the four sops-rendered secret files
        # via $CREDENTIALS_DIRECTORY and writes a combined AWS credentials
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

        # Idempotent: rewrite the credentials file only when its content
        # differs from what we would write (e.g. after secret rotation),
        # so an unchanged setup is a no-op.
        wanted=$(mktemp)
        trap 'rm -f "$wanted"' EXIT
        cat > "$wanted" <<EOF
        [${garageAlias}]
        aws_access_key_id=$garageAccessKey
        aws_secret_access_key=$garageSecretKey
        region=${garageRegion}
        EOF

        if [ ! -f "$dir/credentials" ] || [ "$(md5sum "$wanted" | cut -d' ' -f1)" != "$(md5sum "$dir/credentials" | cut -d' ' -f1)" ]; then
          install -m 600 -o $user -g $group "$wanted" "$dir/credentials"
        fi
      '';

      setupMc = pkgs.writeShellScriptBin "setup-mc" ''
        #!/usr/bin/env bash
        set -euo pipefail

        config_dir=$1
        export MC_CONFIG_DIR="$config_dir"
        mkdir -p "$config_dir"

        # Idempotent alias set: `mc alias set` rewrites the alias config
        # unconditionally; skip it when the stored alias already matches
        # the desired URL, API, path style, and keys.
        set_alias_if_changed() {
          local name=$1 url=$2 access=$3 secret=$4 api=$5 path=$6
          local current
          if current=$(${getExe pkgs.minio-client} alias list --json "$name" 2>/dev/null) \
            && [ "$(echo "$current" | ${getExe pkgs.jq} -r '.URL')" = "$url" ] \
            && [ "$(echo "$current" | ${getExe pkgs.jq} -r '.api')" = "$api" ] \
            && [ "$(echo "$current" | ${getExe pkgs.jq} -r '.path')" = "$path" ] \
            && [ "$(echo "$current" | ${getExe pkgs.jq} -r '.accessKey')" = "$access" ] \
            && [ "$(echo "$current" | ${getExe pkgs.jq} -r '.secretKey')" = "$secret" ]; then
            return 0
          fi
          ${getExe pkgs.minio-client} --quiet alias set "$name" \
            "$url" "$access" "$secret" \
            --api "$api" \
            --path "$path"
        }

        set_alias_if_changed ${garageAlias} \
          http://${garageEndpoint} \
          "$(cat ${secrets."s3/garage/access-key".path})" \
          "$(cat ${secrets."s3/garage/secret-key".path})" \
          ${garageApiVersion} \
          ${garagePathStyle}

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
        trap 'rm -f "$nix_cache_info"' EXIT
        cat > "$nix_cache_info" << EOF
        StoreDir: /nix/store
        WantMassQuery: 1
        Priority: 43
        EOF

        # Idempotent upload: push nix-cache-info only when the remote
        # object is missing or its content differs.
        upload_if_changed() {
          local target=$1
          local remote_hash
          if remote_hash=$(${getExe pkgs.minio-client} cat --quiet "$target" 2>/dev/null | md5sum | cut -d' ' -f1) \
            && [ "$remote_hash" = "$(md5sum "$nix_cache_info" | cut -d' ' -f1)" ]; then
            return 0
          fi
          MC_CONFIG_DIR=/root/.mc \
          ${getExe pkgs.minio-client} cp --quiet "$nix_cache_info" "$target"
        }

        upload_if_changed ${garageAlias}/${garageBucket}/nix-cache-info

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
        after = [
          "network.target"
          "sops.service"
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
          TimeoutStartSec = "60s";
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
