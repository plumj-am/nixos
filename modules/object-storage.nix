{
  flake.modules.nixos.object-storage =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.modules) mkIf mkBefore;
      inherit (lib.meta) getExe;
      inherit (lib.attrsets) optionalAttrs;

      inherit (config.age) secrets;

      bucket = "plumjam";
      endpoint = "fsn1.your-objectstorage.com";
      s3Args = "&priority=10&multipart-upload=true&multipart-threshold=50M&multipart-chunk-size=10M";
      s3Cache = "s3://${bucket}?endpoint=${endpoint}${s3Args}";

      # Upload queue processor script.
      uploadProcessor = pkgs.writeShellScriptBin "nix-upload-processor" ''
        #!/usr/bin/env bash
        set -eu

        QUEUE_DIR=/var/cache/nix/upload-queue
        QUEUE_FILE="$QUEUE_DIR/pending"
        PROCESSING="$QUEUE_DIR/processing"
        DONE="$QUEUE_DIR/done"
        PIDFILE="$QUEUE_DIR/processor.pid"

        mkdir -p "$QUEUE_DIR"
        touch "$QUEUE_FILE" "$PROCESSING" "$DONE"

        echo $$ > "$PIDFILE"
        echo "Started (PID: $$)"

        # Use env set by systemd.
        export AWS_ACCESS_KEY_ID=$(cat "$AWS_ACCESS_KEY_ID_PATH")
        export AWS_SECRET_ACCESS_KEY=$(cat "$AWS_SECRET_ACCESS_KEY_PATH")

        while true; do
          # Move pending to processing.
          if [ -s "$QUEUE_FILE" ]; then
            count=$(wc -l < "$QUEUE_FILE")
            echo "Processing $count new path(s)"
            cat "$QUEUE_FILE" >> "$PROCESSING"
            > "$QUEUE_FILE"
          fi

          # Process each path.
          while IFS= read -r path || [ -n "$path" ]; do
            [ -z "$path" ] && continue
            [ -d "$path" ] || continue

            size=$(du -sb "$path" 2>/dev/null | ${getExe pkgs.gawk} '{print $1}' || echo "0")

            # Check if done previously (avoid duplicates).
            if grep -qx "$path" "$DONE" 2>/dev/null; then
              echo "Skipping $path (already uploaded)"
              continue
            fi

            echo "Uploading $path ($((size / 1024)) KiB)"
            if /run/current-system/sw/bin/nix copy --to "${s3Cache}" "$path" 2>&1; then
              echo "Uploaded $path successfully"
              echo "$path" >> "$DONE"
            else
              echo "Failed to upload $path"
            fi
          done < "$PROCESSING"

          > "$PROCESSING"

          # Trim done file.
          if [ -s "$DONE" ]; then
            tail -n 1000 "$DONE" > "$DONE.tmp" || true
            mv "$DONE.tmp" "$DONE" || true
          fi

          sleep 5
        done
      '';
      setupScript = pkgs.writeShellScriptBin "s3-setup" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Minio client.
        mkdir -p "/home/jam/.mc"
        ${getExe pkgs.minio-client} alias set plumjam-fsn1 \
          https://${endpoint} \
          "$(cat ${secrets.s3AccessKey.path})" \
          "$(cat ${secrets.s3SecretKey.path})" \
          --api s3v4 \
          --path off

        # Environment file for Nix S3 access.
        mkdir -p /etc/nix
        accessKey=$(cat ${secrets.s3AccessKey.path})
        secretKey=$(cat ${secrets.s3SecretKey.path})
        cat > /etc/nix/s3-credentials <<EOF
        AWS_ACCESS_KEY_ID=$accessKey
        AWS_SECRET_ACCESS_KEY=$secretKey
        EOF
        chmod 600 /etc/nix/s3-credentials

        # AWS credentials file for AWS SDK credential chain.
        mkdir -p /root/.aws
        cat > /root/.aws/credentials <<EOF
        [default]
        aws_access_key_id=$accessKey
        aws_secret_access_key=$secretKey
        EOF
        chmod 600 /root/.aws/credentials

        # Set up post-build hook if we have a signing key.
        ${
          if secrets ? nixStoreKey then # sh
            ''
              cat > /etc/nix/post-build-hook.sh <<'HOOK'
              #!/bin/sh
              set -e

              # Add outputs to upload queue.
              QUEUE_DIR=/var/cache/nix/upload-queue
              mkdir -p "$QUEUE_DIR"

              for output in $OUT_PATHS; do
                echo "$output" >> "$QUEUE_DIR/pending"
              done

              exit 0
              HOOK
              chmod +x /etc/nix/post-build-hook.sh
              echo "Post-build hook configured at /etc/nix/post-build-hook.sh"
            ''
          else
            ""
        }

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

      system.activationScripts.s3-setup = {
        deps = [ "agenix" ];
        text = ''
          echo "Setting up S3 credentials..."
          ${getExe setupScript}
        '';
      };

      # Systemd service for continuous upload queue processing
      systemd.services.nix-upload-processor = {
        description = "Nix binary cache upload queue processor";
        after = [
          "network.target"
          "nix-daemon.socket"
        ];
        wantedBy = [ "multi-user.target" ];

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
          CPUQuota = "25%";
        };

        environment = {
          AWS_ACCESS_KEY_ID_PATH = "${secrets.s3AccessKey.path}";
          AWS_SECRET_ACCESS_KEY_PATH = "${secrets.s3SecretKey.path}";
        };
      };

      nix.settings = {
        extra-substituters = mkBefore [ s3Cache ];

        extra-trusted-public-keys = [
          "yuzu-store.plumj.am:p6zQw/rR/i1GxTNYE9nNMgReiy2PuDwpq6aXW0DKfoo="
          "plum-store.plumj.am:LBmfncp/ftlagUEZOM0NWK2tTH4fIT0Bk2WEBU48CNM="
          "kiwi-store.plumj.am:PMlO9Tv8jZf5huFRsKWBD7ejVASjUXnZS1o7xpsN5hw="
          "sloe-store.plumj.am:1qIquG/lWLGgyeyfFBSNuifrNevsGXFf53Bi0stcsxo="
          # TODO date-store
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
