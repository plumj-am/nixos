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

      bucket = "plumjam";
      prefix = "nix";
      endpoint = "fsn1.your-objectstorage.com";
      s3Args = "&priority=43&multipart-upload=true&multipart-threshold=50M&multipart-chunk-size=10M";
      s3Cache = "s3://${bucket}/${prefix}?endpoint=${endpoint}${s3Args}";

      uploadProcessor = pkgs.writeShellScriptBin "nix-upload-processor" ''
        #!/usr/bin/env bash
        set -eu

        QUEUE_DIR=/var/lib/nix-upload-queue
        QUEUE_FILE="$QUEUE_DIR/pending"
        PROCESSING="$QUEUE_DIR/processing"
        DONE="$QUEUE_DIR/done"

        mkdir -p "$QUEUE_DIR"
        touch "$QUEUE_FILE" "$PROCESSING" "$DONE"

        # Use env set by systemd.
        export AWS_ACCESS_KEY_ID=$(cat "$AWS_ACCESS_KEY_ID_PATH")
        export AWS_SECRET_ACCESS_KEY=$(cat "$AWS_SECRET_ACCESS_KEY_PATH")
        export AWS_EC2_METADATA_DISABLED=true

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
            cat "$QUEUE_FILE" >> "$PROCESSING"
            > "$QUEUE_FILE"
          fi

          # process
          while IFS= read -r path || [ -n "$path" ]; do
            [ -z "$path" ] && continue
            [ -d "$path" ] || continue

            # Check in-memory set before doing any work.
            if [[ -v DONE_PATHS["$path"] ]]; then
              echo "Skipping $path (already uploaded)"
              continue
            fi

            size=$(du -sb "$path" 2>/dev/null | ${getExe pkgs.gawk} '{print $1}' || echo "0")
            echo "Uploading $path ($((size / 1024)) KiB)"
            if ${getExe pkgs.nix} copy --to "${s3Cache}" "$path" 2>&1; then
              echo "Uploaded $path successfully"
              echo "$path" >> "$DONE"
              DONE_PATHS["$path"]=1
            else
              echo "Failed to upload $path"
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
      setupScript = pkgs.writeShellScriptBin "s3-setup" ''
        #!/usr/bin/env bash
        set -euo pipefail

        export MC_CONFIG_DIR=${config.users.users.jam.home}/.mc
        if [ -f /root/.aws/credentials ] && ${getExe pkgs.minio-client} alias list plumjam-fsn1 &>/dev/null; then
          echo "S3 credentials already configured, skipping"
          exit 0
        fi

        ${getExe pkgs.minio-client} alias set plumjam-fsn1 \
          https://${endpoint} \
          "$(cat ${secrets.s3AccessKey.path})" \
          "$(cat ${secrets.s3SecretKey.path})" \
          --api s3v4 \
          --path off

        mkdir -p /root/.aws
        accessKey=$(cat ${secrets.s3AccessKey.path})
        secretKey=$(cat ${secrets.s3SecretKey.path})
        cat > /root/.aws/credentials <<EOF
        [default]
        aws_access_key_id=$accessKey
        aws_secret_access_key=$secretKey
        EOF
        chmod 600 /root/.aws/credentials

        echo "S3 setup complete."
        echo "  Bucket: ${bucket}"
        echo "  Endpoint: ${endpoint}"
        echo "  Substituter: ${s3Cache}"
        echo "  Signing key: ${if secrets ? nixStoreKey then "enabled" else "disabled"}"
      '';
    in
    mkIf (secrets ? s3AccessKey && secrets ? s3SecretKey) {
      environment.systemPackages = [
        pkgs.minio-client
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

      systemd.tmpfiles.rules = singleton "d ${config.users.users.jam.home}/.mc 0755 jam users -";

      system.activationScripts.s3-setup = {
        deps = singleton "agenix";
        text = ''
          echo "Setting up S3 credentials..."
          ${getExe setupScript}
        '';
      };

      systemd.services.nix-upload-processor = {
        description = "Nix binary cache upload queue processor";
        after = [
          "network.target"
          "nix-daemon.socket"
        ];
        wantedBy = singleton "multi-user.target";

        serviceConfig = {
          ExecStart = "${getExe uploadProcessor}";
          LoadCredential = [
            "s3-access-key:${secrets.s3AccessKey.path}"
            "s3-secret-key:${secrets.s3SecretKey.path}"
          ];
          Restart = "on-failure";
          RestartSec = "10s";
          StateDirectory = "nix-upload-queue";
          StateDirectoryMode = "0755";
          CPUQuota =
            let
              cores = config.systemSpecs.cores;
            in
            "${toString (cores * 50)}%";
        };

        environment = {
          AWS_ACCESS_KEY_ID_PATH = "${secrets.s3AccessKey.path}";
          AWS_SECRET_ACCESS_KEY_PATH = "${secrets.s3SecretKey.path}";
          AWS_EC2_METADATA_DISABLED = "true";
        };
      };

      nix.settings = {
        extra-substituters = singleton s3Cache;

        extra-trusted-public-keys = [
          "yuzu-store.plumj.am:rRhcZfgv1nSDQxDhgzaudcpyl/JtqoEf4QOsPble7S8="
          "yuzu-store.plumj.am:p6zQw/rR/i1GxTNYE9nNMgReiy2PuDwpq6aXW0DKfoo=" # TODO: Remove after 2026-06-01
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
