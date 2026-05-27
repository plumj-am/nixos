{
  flake.modules.nixos.circus =
    {
      inputs,
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton filter;
      inherit (lib.attrsets) attrsToList;
      inherit (lib') merge;
      inherit (config.networking) domain hostName;

      port = 8012;

      circusPackages = inputs.circus.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = singleton inputs.circus.nixosModules.default;

      environment.systemPackages = [
        circusPackages.circus-migrate-cli
        pkgs.nix-eval-jobs
      ];

      age.secrets = {
        # circusGiteaWebhookSecret = {
        #   rekeyFile = ../secrets/circus-gitea-webhook-secret.age;
        #   owner = "circus";
        # };
        circusPlumjamPassword = {
          rekeyFile = ../secrets/circus-plumjam-password.age;
          owner = "circus";
        };
        circusForgejoToken = {
          rekeyFile = ../secrets/circus-forgejo-token.age;
          owner = "circus";
        };
      };

      services.postgresql.ensureDatabases = singleton "circus";

      systemd = {
        tmpfiles.rules = [
          "d /var/lib/circus/logs 0750 circus circus -"
          "d /nix/var/nix/gcroots/per-user/circus 0755 circus circus -"
        ];
      };

      services.circus = {
        enable = true;
        server.enable = true;
        evaluator.enable = true;
        queueRunner.enable = true;

        package = circusPackages.circus-server;
        evaluatorPackage = circusPackages.circus-evaluator;
        queueRunnerPackage = circusPackages.circus-queue-runner;
        migratePackage = circusPackages.circus-migrate-cli;

        # Mostly set to defaults from:
        # <https://github.com/manic-systems/circus/blob/1e4f89de2a117430023d4af490f32bcee7fe7104/crates/common/src/config.rs>
        # So I have them for reference.
        settings = {
          oauth.github = {
            client_id = "";
            client_secret = "";
            redirect_uri = "";
          };

          server = {
            host = "127.0.0.1";
            inherit port;
            request_timeout = 30;
            max_body_size = 10485760;
            # api_key = ""; # None
            allowed_origins = [ ];
            cors_permissive = false;
            rate_limit_rps = 100; # requests per second per IP (prevents DoS)
            rate_limit_burst = 20; # burst size before rate limit enforcement
            allowed_url_schemes = [
              "https"
              "http"
              "git"
              "ssh"
            ];
            force_secure_cookies = true; # enable when behind HTTPS reverse proxy (nginx/caddy)
            # ldap = { }; None
          };

          cache = {
            enabled = true;
            secretKeyFile = config.age.secrets.nixStoreKey.path;
            compression = "zstd";
            cache_url = "http://${hostName}.taild29fec.ts.net:5000";
          };

          # Will see if nix-upload-processor handles this for us.
          cache_upload = {
            enabled = false;
            store_uri = "";
            s3 = {
              endpoint_url = "";
              prefix = "nix";
              use_path_style = true;
              access_key_id = "";
              secret_access_key = "";
            };
            upload_concurrency = 4;
            upload_max_retries = 3;
            fail_build_on_upload_error = false;
          };

          database = {
            url = "postgresql:///circus?host=/run/postgresql";
            connect_timeout = 30;
            idle_timeout = 600;
            max_connections = 20;
            max_lifetime = 1800;
            min_connections = 5;
          };

          evaluator = {
            git_timeout = 600;
            nix_timeout = 3600;
            poll_interval = 60;
            restrict_eval = true;
            max_concurrent_evals = 4;
            allow_ifd = false;
            strict_errors = false; # Abort on first error or not.
          };

          notifications = {
            webhook_url = "";
            github_token = "";
            gitea_url = "https://git.plumj.am";
            gitea_token = "";
            gitlab_url = "";
            gitlab_token = "";
            email = {
              smtp_host = "";
              smtp_port = 0;
              smtp_user = "";
              smtp_password = "";
              from_address = "";
              to_addresses = [ "" ];
              tls = false;
              on_failure_only = false;
            };
            alerts = {
              enabled = false;
              error_threshold = 20.0;
              time_window_minutes = 60;
            };
            slack = {
              webhook_url = "";
              on_failure_only = false;
            };
            enable_retry_queue = true;
            max_retry_attempts = 5;
            retention_days = 7;
            retry_poll_interval = 5;
          };

          queue_runner = {
            workers = 4;
            poll_interval = 5;
            build_timeout = 3600;
            strict_errors = false; # Abort on first error or not.
            failed_paths_cache = true;
            failed_paths_ttl = 86400; # 24h
            unsupported_timeout = 0; # For unsupported system build timeouts (useless, for Hydra compat).
            scheduling_strategy = "speed_factor_only"; # TODO: Check other options.
            # psi_threshold = 50.0; # None or 0.0-100.0
            psi_check_timeout = 5;
          };

          signing = {
            enabled = true;
            key_file = config.age.secrets.nixStoreKey.path;
          };

          logs = {
            log_dir = "/var/lib/circus/logs";
            compress = true;
          };
          tracing = {
            level = "info";
            format = "compact";
            show_targets = true;
            show_timestamps = true;
          };

          gc = {
            enabled = true;
            gc_roots_dir = "/nix/var/nix/gcroots/per-user/circus/circus-roots";
            max_age_days = 30;
            cleanup_interval = 3600;
          };
        };

        declarative = {
          projects = [
            {
              name = "grove";
              repositoryUrl = "https://git.plumj.am/PlumWorks/grove";
              description = "The PlumWorks Monorepo";

              members = [
                {
                  username = "PlumJam";
                  role = "admin"; # member (default), admin, maintainer.
                }
              ];

              jobsets = [
                {
                  enabled = true;
                  name = "checks";
                  flakeMode = true;
                  nixExpression = "checks"; # flake output ".#checks"
                  checkInterval = 60;
                  state = "enabled"; # enabled (default), disabled, one_shot, one_at_a_time.
                  branch = null; # Git branch to track, default repo default.
                  schedulingShares = 100; # Higher = higher priority.
                  keepNr = 3; # Number of recent successful evals to retain for GC pinning.
                  inputs = [ ]; # Determined automatically.
                }
              ];

              notifications = [
                {
                  enabled = false;
                  notificationType = "webhook"; # github_status, email, gitlab_status, gitea_status, webhook.
                  config = {
                    # settingsType is TOML - need to check source probably.
                  };
                }
              ];

              webhooks = [
                {
                  enabled = false;
                  forgeType = "gitea"; # gitea, github, gitlab.
                  # secretFile = config.age.secrets.circusGiteaWebhookSecret.path;
                }
              ];

              # Release channels for the project.
              channels = [
                # {
                #   name = "";
                #   jobsetName = "";
                # }
              ];
            }
            {
              name = "nixos";
              repositoryUrl = "https://git.plumj.am/PlumJam/nixos";
              description = "PlumJam's NixOS configuration collection";

              members = [
                {
                  username = "PlumJam";
                  role = "admin"; # member (default), admin, maintainer.
                }
              ];

              jobsets = [
                {
                  enabled = true;
                  name = "checks";
                  flakeMode = true;
                  nixExpression = "checks"; # flake output ".#checks"
                  checkInterval = 60;
                  state = "enabled"; # enabled (default), disabled, one_shot, one_at_a_time.
                  branch = null; # Git branch to track, default repo default.
                  schedulingShares = 100; # Higher = higher priority.
                  keepNr = 3; # Number of recent successful evals to retain for GC pinning.
                  inputs = [ ]; # Determined automatically.
                }
              ];

              notifications = [
                {
                  enabled = false;
                  notificationType = "webhook"; # github_status, email, gitlab_stable, gitea_status, webhook.
                  config = {
                    # settingsType is TOML - need to check source probably.
                  };
                }
              ];

              # Release channels for the project.
              channels = [
                # {
                #   name = "";
                #   jobsetName = "";
                # }
              ];
            }
          ];

          apiKeys = [
            {
              name = "git.plumj.am/PlumJam token";
              keyFile = config.age.secrets.circusForgejoToken.path;
              # admin (default), read-only, create-projects, eval-jobset,
              # cancel-build, restart-jobs, bump-to-front.
              role = "admin";
            }
          ];

          users = {
            PlumJam = {
              enabled = true;
              email = "me@plumj.am";
              fullName = "PlumJam";
              passwordFile = config.age.secrets.circusPlumjamPassword.path;
              # admin, read-only, create-projects, eval-jobset,
              # cancel-build, restart-jobs, bump-to-front
              role = "admin";

            };
          };

          remoteBuilders =
            inputs.self.nixosConfigurations
            |> attrsToList
            |> filter (
              { name, value }: name != config.networking.hostName && value.config.systemSpecs.builder.enable
            )
            |> map (
              { name, value }:
              {
                enabled = true;
                inherit name;
                sshUri = "ssh://build@${name}";
                systems = singleton value.config.nixpkgs.hostPlatform.system;
                maxJobs = value.config.systemSpecs.cores;
                speedFactor = value.config.systemSpecs.speedFactor;
                supportedFeatures = [
                  "benchmark"
                  "big-parallel"
                  "kvm"
                  "nixos-test"
                ];
                mandatoryFeatures = [ ];
                sshKeyFile = "/root/.ssh/id";
                publicHostKey = config.age.rekey.hostPubkey;
              }
            );
        };
      };

      services.nginx.virtualHosts."circus.${domain}" = merge config.services.nginx.sslTemplate {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          extraConfig = # nginx
            ''
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              client_max_body_size 50M;
            '';
        };
      };
    };
}
