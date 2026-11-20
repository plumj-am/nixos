{
  flake.modules.nixos.rustfs =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.modules) merge mkIf mkMerge;
      inherit (lib.strings) concatMapStringsSep;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      cfg = config.rustfs;

      # The upstream flake owns the systemd service, user, and credential
      # handling. Use its client too, so the CLI matches the server version.
      rustfsClient = inputs.rustfs.packages.${pkgs.stdenv.hostPlatform.system}.rustfs-client;

      # Garage keeps 8015/8016/8017. RustFS deliberately uses different
      # ports so both backends can run side by side for comparison.
      # Keep apiPort in sync with modules/s3.nix.
      fqdnS3 = "s3-rustfs.${domain}";

      # Keep the client region unchanged when switching backends.
      rustfsRegion = "garage";

      policy = pkgs.writeText "rustfs-s3-policy.json" (
        builtins.toJSON {
          Version = "2012-10-17";
          Statement = [
            {
              Effect = "Allow";
              Action = [
                "s3:AbortMultipartUpload"
                "s3:DeleteObject"
                "s3:GetObject"
                "s3:PutObject"
              ];
              Resource = map (bucket: "arn:aws:s3:::${bucket}/*") cfg.buckets;
            }
            {
              Effect = "Allow";
              Action = [ "s3:ListBucket" ];
              Resource = map (bucket: "arn:aws:s3:::${bucket}") cfg.buckets;
            }
            {
              # RustFS uses the MinIO-style action names, not AWS's
              # `s3:GetLifecycleConfiguration`/`PutLifecycleConfiguration`.
              Effect = "Allow";
              Action = [
                "s3:GetBucketLifecycle"
                "s3:PutBucketLifecycle"
              ];
              Resource = map (bucket: "arn:aws:s3:::${bucket}") cfg.buckets;
            }
          ];
        }
      );

      # Creates the buckets and the scoped service account that the rest of
      # the repo already uses. The s3-setup service (modules/s3.nix) runs
      # after this and adds nix-cache-info and the 14-day ILM rule.
      rustfsBootstrap = pkgs.writeShellScript "rustfs-bootstrap" ''
        set -euo pipefail

        # `rc` keeps its alias state under HOME. Keep it out of the way; the
        # unit is idempotent and does not need to persist credentials.
        export HOME="$(mktemp -d)"
        export XDG_CONFIG_HOME="$HOME/.config"
        trap 'rm -rf "$HOME"' EXIT

        rc=${getExe rustfsClient}
        curl=${getExe pkgs.curl}

        # The upstream module loads these as systemd credentials; the
        # bootstrap service loads the same files and exports them for `rc`.
        export RUSTFS_ACCESS_KEY="$(cat "$CREDENTIALS_DIRECTORY/access-key")"
        export RUSTFS_SECRET_KEY="$(cat "$CREDENTIALS_DIRECTORY/secret-key")"

        for _ in $(seq 1 60); do
          if "$curl" --fail --silent --show-error \
            "http://127.0.0.1:${toString cfg.apiPort}/health/ready" >/dev/null; then
            break
          fi
          sleep 2
        done

        if ! "$curl" --fail --silent \
          "http://127.0.0.1:${toString cfg.apiPort}/health/ready" >/dev/null; then
          echo "rustfs did not become ready in time" >&2
          exit 1
        fi

        "$rc" alias set rustfs \
          "http://127.0.0.1:${toString cfg.apiPort}" \
          "$RUSTFS_ACCESS_KEY" \
          "$RUSTFS_SECRET_KEY"

        ${concatMapStringsSep "\n" (bucket: ''
          if ! "$rc" ls "rustfs/${bucket}" >/dev/null 2>&1; then
            "$rc" mb "rustfs/${bucket}"
          fi
        '') cfg.buckets}

        key_id="$(cat "$CREDENTIALS_DIRECTORY/s3-garage-access-key")"
        key_secret="$(cat "$CREDENTIALS_DIRECTORY/s3-garage-secret-key")"

        if ! "$rc" admin access-key info "rustfs/" "$key_id" >/dev/null 2>&1; then
          "$rc" admin service-account create "rustfs/" \
            "$key_id" "$key_secret" \
            --policy ${policy} >/dev/null
        else
          # Re-apply the policy so changes to the module reach an existing
          # account. Creating is not enough: the account is only created once.
          "$rc" admin service-account update "rustfs/" "$key_id" \
            --policy ${policy} >/dev/null
        fi
      '';
    in
    {
      imports = [ inputs.rustfs.nixosModules.rustfs ];

      # NixOS already includes its own RustFS module. Disable it so the
      # upstream module owns `services.rustfs`.
      disabledModules = [ "services/web-servers/rustfs.nix" ];

      options.rustfs = {
        enable = lib.mkEnableOption "RustFS, as an alternative to the Garage S3 backend";

        accessKeyFile = lib.mkOption {
          type = lib.types.path;
          default = "/run/secrets/rustfs-access-key";
          description = ''
            File with the RustFS root access key. This module does not create
            or decrypt it: render it with sops-nix or another secret mechanism.
          '';
        };

        secretKeyFile = lib.mkOption {
          type = lib.types.path;
          default = "/run/secrets/rustfs-secret-key";
          description = ''
            File with the RustFS root secret key. This module does not create
            or decrypt it: render it with sops-nix or another secret mechanism.
          '';
        };

        apiPort = lib.mkOption {
          type = lib.types.port;
          default = 9015;
          description = "S3 API port. Distinct from Garage's 8015 so both can run.";
        };

        consolePort = lib.mkOption {
          type = lib.types.port;
          default = 9016;
          description = "Console port. Bound to loopback.";
        };

        consoleEnable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable the RustFS web console on loopback.";
        };

        volume = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/rustfs";
          description = "Data directory owned by the RustFS service user.";
        };

        buckets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "nix"
            "backups"
          ];
          description = "Buckets created by the bootstrap service.";
        };
      };

      config = mkMerge [
        {
          assertions = [
            {
              assertion = config.s3.backend != "rustfs" || cfg.enable;
              message = ''
                s3.backend = "rustfs" requires rustfs.enable = true: the shared
                cache endpoint would point at a server that is not running.
              '';
            }
            {
              assertion = cfg.buckets != [ ];
              message = "rustfs.buckets must not be empty.";
            }
          ];
        }

        (mkIf cfg.enable {
          services.rustfs = {
            enable = true;

            # Upstream 1.0.5 source package; the first build takes a long time.
            package = inputs.rustfs.packages.${pkgs.stdenv.hostPlatform.system}.rustfs;

            volumes = [ cfg.volume ];
            address = ":${toString cfg.apiPort}";
            inherit (cfg) consoleEnable;
            consoleAddress = "127.0.0.1:${toString cfg.consolePort}";
            inherit (cfg) accessKeyFile;
            inherit (cfg) secretKeyFile;

            extraEnvironmentVariables = {
              # Keep the existing client configuration (region, alias, and
              # bucket) unchanged while switching the backend.
              RUSTFS_REGION = rustfsRegion;

              # No outbound version check, and fsync acknowledged writes:
              # the single-disk host has no parity to recover from.
              RUSTFS_CHECK_UPDATE = "false";
              RUSTFS_DURABILITY_MODE = "strict";
              RUSTFS_NEW_BUCKET_DURABILITY_MODE = "strict";
            };
          };

          services.ferronVhosts.${fqdnS3} = merge config.services.ferron.sslTemplate {
            proxy = "http://localhost:${toString cfg.apiPort}";

            config = # kdl
              ''
                ${config.services.ferron.headers}
              '';
          };
          systemd.services.rustfs-bootstrap = {
            after = [ "rustfs.service" ];
            requires = [ "rustfs.service" ];
            wantedBy = [ "multi-user.target" ];

            path = [
              pkgs.coreutils
              pkgs.curl
              rustfsClient
            ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              TimeoutStartSec = "10min";
              PrivateTmp = true;

              # Root credentials for this bootstrap only. The shared client
              # key pair is loaded separately below and becomes a scoped
              # service account, so consumers never receive the root key.
              LoadCredential = [
                "access-key:${cfg.accessKeyFile}"
                "secret-key:${cfg.secretKeyFile}"
                "s3-garage-access-key:${secrets."s3/garage/access-key".path}"
                "s3-garage-secret-key:${secrets."s3/garage/secret-key".path}"
              ];

              ExecStart = rustfsBootstrap;
            };
          };
        })
      ];
    };
}
