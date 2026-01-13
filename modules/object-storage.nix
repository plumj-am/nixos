{
  flake.modules.nixos.object-storage =
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

      inherit (config.age) secrets;

      bucket = "plumjam";
      endpoint = "fsn1.your-objectstorage.com";
      s3Cache = "s3://${bucket}?endpoint=${endpoint}";

      setupScript = pkgs.writeShellScriptBin "s3-setup" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Minio client.
        mkdir -p "$HOME/.mc"
        ${getExe pkgs.minio-client} alias set plumjam-fsn1 \
          https://${endpoint} \
          "$(sudo cat ${secrets.s3AccessKey.path})" \
          "$(sudo cat ${secrets.s3SecretKey.path})" \
          --api s3v4 \
          --path off

        # Environment file for Nix S3 access.
        sudo mkdir -p /etc/nix
        accessKey=$(sudo cat ${secrets.s3AccessKey.path})
        secretKey=$(sudo cat ${secrets.s3SecretKey.path})
        sudo tee /etc/nix/s3-credentials > /dev/null <<EOF
        AWS_ACCESS_KEY_ID=$accessKey
        AWS_SECRET_ACCESS_KEY=$secretKey
        EOF
        sudo chmod 600 /etc/nix/s3-credentials

        # Set up post-build hook if we have a signing key.
        ${
          if secrets ? nixStoreKey then # sh
            ''
              sudo tee /etc/nix/post-build-hook.sh > /dev/null <<'HOOK'
              #!/bin/sh
              set -e
              # Read AWS credentials from agenix
              export AWS_ACCESS_KEY_ID=$(cat ${secrets.s3AccessKey.path})
              export AWS_SECRET_ACCESS_KEY=$(cat ${secrets.s3SecretKey.path})
              # Sign the output paths
              for output in $OUT_PATHS; do
                /run/current-system/sw/bin/nix store sign --recursive --key-file ${secrets.nixStoreKey.path} "$output" 2>/dev/null || true
              done
              # Upload to S3 cache
              for output in $OUT_PATHS; do
                /run/current-system/sw/bin/nix copy --to "${s3Cache}" "$output"
              done
              HOOK
              sudo chmod +x /etc/nix/post-build-hook.sh
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
      ];

      nix.settings = {
        extra-substituters = [ s3Cache ];

        extra-trusted-public-keys = [
          "yuzu-store.plumj.am:p6zQw/rR/i1GxTNYE9nNMgReiy2PuDwpq6aXW0DKfoo="
          "plum-store.plumj.am:LBmfncp/ftlagUEZOM0NWK2tTH4fIT0Bk2WEBU48CNM="
          "kiwi-store.plumj.am:PMlO9Tv8jZf5huFRsKWBD7ejVASjUXnZS1o7xpsN5hw="
          # TODO date-store
          # TODO ?lime-store?
          "blackwell-store.plumj.am:o9oPrcWuBcXiC0YJkf9pbxkITxc0qqS2aB8QKiYnzoo="
        ];
      }
      // optionalAttrs (secrets ? nixStoreKey) {
        post-build-hook = "/etc/nix/post-build-hook.sh";
        secret-key-files = secrets.nixStoreKey.path;
      };
    };
}
