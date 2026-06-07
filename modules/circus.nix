let
  sharedSettings = config: hostName: {
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
      connect_timeout = 30;
      idle_timeout = 600;
      max_connections = 20;
      max_lifetime = 1800;
      min_connections = 5;
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
in
{
  flake.modules.nixos.circus-server =
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
      inherit (lib.attrsets) attrsToList genAttrs recursiveUpdate;
      inherit (lib.trivial) const flip;
      inherit (lib.modules) mkDefault mkForce;
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
        circusGiteaPlumJamNixosWebhookSecret = {
          rekeyFile = ../secrets/circus-gitea-plumjam-nixos-webhook-secret.age;
          owner = "circus";
        };
        circusPlumjamPassword = {
          rekeyFile = ../secrets/circus-plumjam-password.age;
          owner = "circus";
        };
        circusForgejoToken = {
          rekeyFile = ../secrets/circus-forgejo-token.age;
          owner = "circus";
        };
        circusSshKey = {
          rekeyFile = ../secrets/plum-circus-ssh-key.age;
          owner = "circus";
          group = "circus";
          mode = "600";
        };
      };

      services.postgresql = {
        ensureDatabases = singleton "circus";
        settings.listen_addresses = "localhost,${hostName}.taild29fec.ts.net";

        # Accept evaluator hosts.
        authentication = ''
          local circus circus trust
          host circus circus date.taild29fec.ts.net trust
          host circus circus sloe.taild29fec.ts.net trust
        '';
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/circus/logs 0750 circus circus -"
        "d /nix/var/nix/gcroots/per-user/circus 0755 circus circus -"
      ];

      services.circus = {
        enable = true;
        server.enable = mkForce true;
        evaluator.enable = mkDefault false;
        queueRunner.enable = mkDefault false;

        package = circusPackages.circus-server;
        migratePackage = circusPackages.circus-migrate-cli;

        # Mostly set to defaults from:
        # <https://github.com/manic-systems/circus/blob/1e4f89de2a117430023d4af490f32bcee7fe7104/crates/common/src/config.rs>
        # So I have them for reference.
        settings = recursiveUpdate (sharedSettings config hostName) {
          oauth.github = {
            client_id = "";
            client_secret = "";
            redirect_uri = "";
          };

          database.url =
            if hostName == "plum" then
              "postgresql:///circus?host=/run/postgresql"
            else
              "postgresql://circus@plum.taild29fec.ts.net/circus";

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
            config_editor_enabled = false;

            page_access = flip genAttrs (const "authenticated") [
              "home"
              "projects"
              "project"
              "jobset"
              "jobset_jobs"
              "evaluations"
              "evaluation"
              "builds"
              "build"
              "queue"
              "channels"
              "news"
              "starred"
              "metrics"
            ];
          };
        };

        declarative = {
          projects = [
            {
              name = "grove";
              repositoryUrl = "https://gerrit.plumj.am/grove";
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

              webhooks = [
                {
                  enabled = false;
                  forgeType = "gitea"; # gitea, github, gitlab.
                  # secretFile = config.age.secrets.circusGiteaPlumJamNixosWebhookSecret.path;
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

              webhooks = [
                {
                  enabled = true;
                  forgeType = "gitea"; # gitea, github, gitlab.
                  secretFile = config.age.secrets.circusGiteaPlumJamNixosWebhookSecret.path;
                }
              ];

              notifications = [
                {
                  enabled = true;
                  notificationType = "gitea_status";
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
            {
              name = "circusGerritApiKey";
              keyFile = config.age.secrets.circusGerritApiKey.path;
              # admin (default), read-only, create-projects, eval-jobset,
              # cancel-build, restart-jobs, bump-to-front.
              role = "eval-jobset";
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
                sshUri = "ssh-ng://build@${name}";
                systems = singleton value.config.nixpkgs.hostPlatform.system;
                maxJobs = value.config.systemSpecs.cores;
                speedFactor = value.config.systemSpecs.speedFactor;
                supportedFeatures = [
                  "benchmark"
                  "big-parallel"
                  "kvm"
                  "nixos-test"
                  "uid-range"
                ];
                mandatoryFeatures = [ ];
                sshKeyFile = config.age.secrets.circusSshKey.path;
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

  flake.modules.nixos.circus-evaluator =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) recursiveUpdate;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkDefault mkForce;
      inherit (config.networking) hostName;

      circusPackages = inputs.circus.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = singleton inputs.circus.nixosModules.default;

      environment.systemPackages = singleton pkgs.nix-eval-jobs;

      systemd.tmpfiles.rules = [
        "d /var/lib/circus/logs 0750 circus circus -"
        "d /nix/var/nix/gcroots/per-user/circus 0755 circus circus -"
      ];

      age.secrets.circusGerritPassword = {
        rekeyFile = ../secrets/circus-gerrit-password.age;
        owner = "circus";
        mode = "400";
      };

      services.circus = {
        enable = true;
        server.enable = mkDefault false;
        evaluator.enable = mkForce true;
        queueRunner.enable = mkDefault false;

        evaluatorPackage = circusPackages.circus-evaluator;

        database.createLocally = false;
        settings = recursiveUpdate (sharedSettings config hostName) {
          database.url =
            if hostName == "plum" then
              "postgresql:///circus?host=/run/postgresql"
            else
              "postgresql://circus@plum.taild29fec.ts.net/circus";

          evaluator = {
            git_http_username = "circus";
            git_timeout = 600;
            nix_timeout = 3600;
            poll_interval = 60;
            restrict_eval = true;
            max_concurrent_evals = 2;
            allow_ifd = false;
            strict_errors = false; # Abort on first error or not.
          };
        };
      };

    };

  flake.modules.nixos.circus-queue-runner =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) recursiveUpdate;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkDefault mkForce;
      inherit (config.networking) hostName;

      circusPackages = inputs.circus.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = singleton inputs.circus.nixosModules.default;

      systemd.tmpfiles.rules = [
        "d /var/lib/circus/logs 0750 circus circus -"
        "d /nix/var/nix/gcroots/per-user/circus 0755 circus circus -"
      ];
      services.circus = {
        enable = true;
        server.enable = mkDefault false;
        evaluator.enable = mkDefault false;
        queueRunner.enable = mkForce true;

        queueRunnerPackage = circusPackages.circus-queue-runner;

        database.createLocally = false;
        settings = recursiveUpdate (sharedSettings config hostName) {
          database.url =
            if hostName == "plum" then
              "postgresql:///circus?host=/run/postgresql"
            else
              "postgresql://circus@plum.taild29fec.ts.net/circus";

          queue_runner = {
            workers = 4;
            poll_interval = 5;
            build_timeout = 3600;
            strict_errors = false; # Abort on first error or not.
            failed_paths_cache = false; # TODO: re-enable once working
            failed_paths_ttl = 86400; # 24h
            unsupported_timeout = 0; # For unsupported system build timeouts (useless, for Hydra compat).
            scheduling_strategy = "speed_factor_only"; # TODO: Check other options.
            # psi_threshold = 50.0; # None or 0.0-100.0
            psi_check_timeout = 5;

            rpc = {
              bind = "0.0.0.0:8014";
              auth_tokens = [
                "47bf8f34370b54dfe24e8e2b09da65dec4296c9d9a4b7d8a299c3c8fbf8ae9c9"
                "7c229876088043eab303adaed8338858096fbb22b0224cc06b2476c296c0dc39"
                "5d586afe97ee23e3fbe3d8560a16bcaaea97195c902d73f92593b16451bd063d"
                "5fc06cce2184c44d9082bff838c73351813b056894a9137387e774d48929cf4d"
                "6131b1c964ec806204012bebed3df245ca70ba3b912cc5c9ad1033129d6415b4"
              ];
            };
          };
        };
      };

    };

  flake.modules.nixos.circus-agent =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.age) secrets;
      inherit (config.networking) hostName;
      inherit (config) systemSpecs;

      port = "8014";

      circusPkgs = inputs.circus.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = singleton inputs.circus.nixosModules.circus-agent;

      age.secrets.circusAgentAuthToken = {
        rekeyFile = ../secrets/${hostName}-circus-agent-auth-token.age;
        owner = "circus-agent";
        mode = "400";
      };

      services.circus-agent = {
        enable = true;
        package = circusPkgs.circus-agent;

        authTokenFile = secrets.circusAgentAuthToken.path;

        settings.agent = {
          name = "circus-builder-${hostName}";
          runner_url =
            if hostName == "plum" then
              "circus://0.0.0.0:${port}"
            else
              "circus://plum.taild29fec.ts.net:${port}";

          systems = singleton config.nixpkgs.hostPlatform.system;
          supported_features = [
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
            "uid-range"
          ];
          max_jobs = systemSpecs.cores;
          speed_factor = systemSpecs.speedFactor;
        };
      };
    };

  flake.modules.nixos.gerrit-circus-bridge =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;

      secrets = config.age.secrets;
    in
    {
      imports = singleton inputs.gerrit-circus-bridge.nixosModules.default;

      age.secrets = {
        circusGerritApiKey = {
          rekeyFile = ../secrets/circus-gerrit-api-key.age;
          owner = "circus";
          mode = "400";
        };
        circusGerritPassword = {
          rekeyFile = ../secrets/circus-gerrit-password.age;
          owner = "circus";
          mode = "400";
        };
      };

      services.gerrit-circus-bridge = {
        enable = true;
        circusApiKeyFile = secrets.circusGerritApiKey.path;
        gerritPasswordFile = secrets.circusGerritPassword.path;
      };
    };
}
