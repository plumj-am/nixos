{
  flake.modules.nixos.s3-upload =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.meta) getExe;
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.lists) singleton;
      inherit (config.age) secrets;

      s3SharedArgs = "&priority=43&multipart-upload=true&multipart-threshold=50M&multipart-chunk-size=10M";

      fsn1Alias = "plumjam-fsn1";
      fsn1Bucket = "plumjam";
      fsn1Prefix = "nix";
      fsn1Endpoint = "fsn1.your-objectstorage.com";
      fsn1PathStyle = "off";
      fsn1ApiVersion = "s3v4";
      fsn1S3Cache = "s3://${fsn1Bucket}/${fsn1Prefix}?endpoint=${fsn1Endpoint}&profile=${fsn1Alias}${s3SharedArgs}";

      garageHostName = "sloe";
      garageHostPort = 8015;
      garageAlias = "plumjam-garage-nix";
      garageBucket = "nix";
      garageEndpoint = "${garageHostName}.taild29fec.ts.net:${toString garageHostPort}";
      garageRegion = "garage";
      garagePathStyle = "on";
      garageApiVersion = "s3v4";
      garageS3Cache = "s3://${garageBucket}?endpoint=${garageEndpoint}&profile=${garageAlias}&region=${garageRegion}${s3SharedArgs}";

      uploadProcessor = pkgs.writeShellScriptBin "nix-upload-processor" ''
        #!/usr/bin/env bash
        set -eu

        QUEUE_DIR=/var/lib/nix-upload-queue
        QUEUE_FILE="$QUEUE_DIR/pending"
        PROCESSING="$QUEUE_DIR/processing"
        DONE="$QUEUE_DIR/done"

        mkdir -p "$QUEUE_DIR"
        touch "$QUEUE_FILE" "$PROCESSING" "$DONE"

        export AWS_EC2_METADATA_DISABLED=true

        upload_to() {
          local cache=$1 path=$2
          case "$cache" in
            *${fsn1Endpoint}*)
              export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/s3-plumjam-fsn1-access-key")
              export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/s3-plumjam-fsn1-secret-key")
              ;;
            *)
              export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/s3-plumjam-garage-nix-access-key")
              export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/s3-plumjam-garage-nix-secret-key")
              ;;
          esac
          ${getExe pkgs.nix} copy --to "$cache" "$path" 2>&1
        }

        # Load already-uploaded paths into associative array to avoid slow grep per path.
        declare -A DONE_PATHS
        while IFS= read -r done_path; do
          DONE_PATHS["$done_path"]=1
        done < "$DONE"

        while true; do
          # pending -> processing
          if [ -s "$QUEUE_FILE" ]; then
            count=$(wc -l < "$QUEUE_FILE")
            echo "Processing $count new path(s)"
            mv "$QUEUE_FILE" "$PROCESSING"
            touch "$QUEUE_FILE"
          fi

          # process
          while IFS= read -r path || [ -n "$path" ]; do
            [ -z "$path" ] && continue
            # [ -d "$path" ] || continue

            # Check in-memory set before doing any work.
            if [[ -v DONE_PATHS["$path"] ]]; then
              echo "Skipping $path (already uploaded)"
              continue
            fi

            size=$(du -sb "$path" 2>/dev/null | ${getExe pkgs.gawk} '{print $1}' || echo "0")
            echo "Uploading $path ($((size / 1024)) KiB)"
            all_ok=true
            for cache in "${fsn1S3Cache}" "${garageS3Cache}"; do
              if upload_to "$cache" "$path"; then
                echo "  -> $cache OK"
              else
                echo "  -> $cache FAILED"
                all_ok=false
              fi
            done
            if $all_ok; then
              echo "Uploaded $path successfully"
              echo "$path" >> "$DONE"
              DONE_PATHS["$path"]=1
            else
              echo "Failed to upload $path to one or more targets"
            fi
          done < "$PROCESSING"

          > "$PROCESSING"

          # Trim done file and reload array.
          if [ -s "$DONE" ]; then
            tail -n 1000 "$DONE" > "$DONE.tmp" || true
            mv "$DONE.tmp" "$DONE" || true
            DONE_PATHS=()
            while IFS= read -r done_path; do
              DONE_PATHS["$done_path"]=1
            done < "$DONE"
          fi

          sleep 5
        done
      '';
      setupAwsCreds = pkgs.writeShellScriptBin "setup-aws-creds" ''
        #!/usr/bin/env bash
        set -euo pipefail

        dir=$1
        user=$2
        group=$3
        mkdir -p "$dir"

        s3PlumjamFsn1AccessKey=$(cat ${secrets.s3PlumjamFsn1AccessKey.path})
        s3PlumjamFsn1SecretKey=$(cat ${secrets.s3PlumjamFsn1SecretKey.path})
        s3PlumjamGarageNixAccessKey=$(cat ${secrets.s3PlumjamGarageNixAccessKey.path})
        s3PlumjamGarageNixSecretKey=$(cat ${secrets.s3PlumjamGarageNixSecretKey.path})

        cat > "$dir/credentials" <<EOF
        [${fsn1Alias}]
        aws_access_key_id=$s3PlumjamFsn1AccessKey
        aws_secret_access_key=$s3PlumjamFsn1SecretKey
        [${garageAlias}]
        aws_access_key_id=$s3PlumjamGarageNixAccessKey
        aws_secret_access_key=$s3PlumjamGarageNixSecretKey
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

        ${getExe pkgs.minio-client} --quiet alias set ${fsn1Alias} \
          https://${fsn1Endpoint} \
          "$(cat ${secrets.s3PlumjamFsn1AccessKey.path})" \
          "$(cat ${secrets.s3PlumjamFsn1SecretKey.path})" \
          --api ${fsn1ApiVersion} \
          --path ${fsn1PathStyle}

        ${getExe pkgs.minio-client} --quiet alias set ${garageAlias} \
          http://${garageEndpoint} \
          "$(cat ${secrets.s3PlumjamGarageNixAccessKey.path})" \
          "$(cat ${secrets.s3PlumjamGarageNixSecretKey.path})" \
          --api ${garageApiVersion} \
          --path ${garagePathStyle}

        ${getExe pkgs.minio-client} --quiet ilm add --expire-days 60 ${fsn1Alias}/${fsn1Bucket}/${fsn1Prefix} 2>/dev/null || true
        ${getExe pkgs.minio-client} --quiet ilm add --expire-days 60 ${garageAlias}/${garageBucket} 2>/dev/null || true
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

                MC_CONFIG_DIR=/root/.mc \
                ${getExe pkgs.minio-client} cp --quiet "$nix_cache_info" ${fsn1Alias}/${fsn1Bucket}/${fsn1Prefix}/nix-cache-info

                MC_CONFIG_DIR=/root/.mc \
                ${getExe pkgs.minio-client} cp --quiet "$nix_cache_info" ${garageAlias}/${garageBucket}/nix-cache-info

                rm "$nix_cache_info"

                echo "S3 setup complete."
                echo "  Fsn1 Bucket: ${fsn1Bucket}"
                echo "  Fsn1 Endpoint: ${fsn1Endpoint}"
                echo "  Fsn1 Substituter: ${fsn1S3Cache}"
                echo "  Garage Bucket: ${garageAlias}"
                echo "  Garage Endpoint: ${garageEndpoint}"
                echo "  Garage Substituter: ${garageS3Cache}"
                echo "  Signing key: ${if secrets ? nixStoreKey then "enabled" else "disabled"}"
      '';
    in
    mkIf
      (
        secrets ? s3PlumjamFsn1AccessKey
        && secrets ? s3PlumjamFsn1SecretKey
        && secrets ? s3PlumjamGarageNixAccessKey
        && secrets ? s3PlumjamGarageNixSecretKey
      )
      {
        environment.systemPackages = [
          pkgs.minio-client
          setupAwsCreds
          setupMc
          setupScript
          uploadProcessor
        ];

        environment.etc = optionalAttrs (secrets ? nixStoreKey) {
          "nix/post-build-hook.sh" = {
            mode = "0755";
            text = ''
              #!/bin/sh
              set -e

              QUEUE_DIR=/var/lib/nix-upload-queue

              for output in $OUT_PATHS; do
                echo "$output" >> "$QUEUE_DIR/pending"
              done

              exit 0
            '';
          };
        };

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
            "agenix.service"
          ];
          before = [ "nix-upload-processor.service" ];
          wantedBy = [ "multi-user.target" ];

          # mc needs glibc.getent
          path = [
            pkgs.glibc.getent
            pkgs.minio-client
            pkgs.coreutils
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = getExe setupScript;
          };
        };

        systemd.services.nix-upload-processor = {
          description = "Nix binary cache upload queue processor";
          after = [
            "network.target"
            "nix-daemon.socket"
            "s3-setup.service"
          ];
          wantedBy = singleton "multi-user.target";

          serviceConfig = {
            ExecStart = "${getExe uploadProcessor}";
            LoadCredential = [
              "s3-plumjam-fsn1-access-key:${secrets.s3PlumjamFsn1AccessKey.path}"
              "s3-plumjam-fsn1-secret-key:${secrets.s3PlumjamFsn1SecretKey.path}"
              "s3-plumjam-garage-nix-access-key:${secrets.s3PlumjamGarageNixAccessKey.path}"
              "s3-plumjam-garage-nix-secret-key:${secrets.s3PlumjamGarageNixSecretKey.path}"
            ];
            Restart = "on-failure";
            RestartSec = "10s";
            StateDirectory = "nix-upload-queue";
            StateDirectoryMode = "0755";
            CPUQuota =
              let
                cores = config.systemInfo.cores;
              in
              "${toString (cores * 50)}%";
          };

          environment = {
            AWS_EC2_METADATA_DISABLED = "true";
          };
        };

        nix.settings = {
          extra-substituters = [
            fsn1S3Cache
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
        }
        // optionalAttrs (secrets ? nixStoreKey) {
          post-build-hook = "/etc/nix/post-build-hook.sh";
          secret-key-files = secrets.nixStoreKey.path;
        };
      };
}
