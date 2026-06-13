{
  flake.modules.nixos.gradient =
    {
      inputs,
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton filter map;
      inherit (lib') merge;
      inherit (config.networking) domain hostName;
      inherit (config.sops) secrets;

      fqdn = "gradient.${domain}";
      listenAddr = "0.0.0.0";
      port = 8018;

      upstreams =
        let
          hosts = [
            {
              display_name = "plum";
              public_key = "plum-store.plumj.am:LBmfncp/ftlagUEZOM0NWK2tTH4fIT0Bk2WEBU48CNM=";
            }
            {
              display_name = "kiwi";
              public_key = "kiwi-store.plumj.am:PMlO9Tv8jZf5huFRsKWBD7ejVASjUXnZS1o7xpsN5hw=";
            }
            {
              display_name = "sloe";
              public_key = "sloe-store.plumj.am:1qIquG/lWLGgyeyfFBSNuifrNevsGXFf53Bi0stcsxo=";
            }
            {
              display_name = "date";
              public_key = "date-store.plumj.am:1sziS/y3AiWPV8TY8pHtK3tYxiN10ujutWDNpo4O1Fg=";
            }
            {
              display_name = "yuzu";
              public_key = "yuzu-store.plumj.am:rRhcZfgv1nSDQxDhgzaudcpyl/JtqoEf4QOsPble7S8=";
            }
          ];
        in
        (
          map (h: {
            inherit (h) display_name public_key;
            type = "external";
            url = "http://${h.display_name}.taild29fec.ts.net:${toString port}";
          })
          <| filter (h: h.display_name != hostName) hosts
        )
        ++ [
          {
            type = "external";
            display_name = "cache.nixos.org";
            url = "https://cache.nixos.org";
            public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
          }
          {
            type = "external";
            display_name = "cache.garnix.io";
            url = "https://cache.garnix.io";
            public_key = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
          }
          {
            type = "external";
            display_name = "nix-community.cachix.org";
            url = "https://nix-community.cachix.org";
            public_key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
          }
        ];
    in
    {
      imports = singleton inputs.gradient.nixosModules.default;

      sops.secrets = {
        "gradient-server/jwt".sopsFile = ../secrets/services/gradient.yaml;
        "gradient-server/crypt".sopsFile = ../secrets/services/gradient.yaml;
        "gradient-server/worker-token".sopsFile = ../secrets/services/gradient.yaml;
        "gradient-server/user-plumjam-password".sopsFile = ../secrets/services/gradient.yaml;
        "gradient-server/org-plumworks-ssh-private-key".sopsFile = ../secrets/services/gradient.yaml;
        # Same as nix-store-key but trim `name:`.
        "gradient-server/cache-signing-key".sopsFile = ../secrets/services/gradient.yaml;
        "gradient-server/forgejo-webhook-access-token".sopsFile = ../secrets/services/gradient.yaml;
        "gradient-server/forgejo-webhook-hmac-secret".sopsFile = ../secrets/services/gradient.yaml;
      };

      environment.systemPackages =
        singleton
          inputs.gradient.packages.${pkgs.stdenv.hostPlatform.system}.gradient-cli;

      services.postgresql = {
        enable = true;
        ensureDatabases = singleton "gradient";
        ensureUsers = singleton {
          name = "gradient";
          ensureDBOwnership = true;
        };
      };

      services.gradient = {
        enable = true;

        inherit listenAddr port;
        domain = fqdn;

        frontend = {
          enable = true;
          url = "https://${fqdn}";
        };

        jwtSecretFile = secrets."gradient-server/jwt".path;
        cryptSecretFile = secrets."gradient-server/crypt".path;

        databaseUrl = "postgresql:///gradient?host=/run/postgresql";

        settings.allowAnonymousCache = false;
        reportErrors = false;

        state = {
          workers = {
            sloe = {
              worker_id = "019ebc40-e764-72a0-816e-09e490f44995";
              organizations = [
                "plumworks"
                "plumjam"
              ];
              token_file = secrets."gradient-server/worker-token".path;
              created_by = "plumjam";
            };
            date = {
              worker_id = "e652ec89-5784-44ed-bbb8-79adbc4f1d0d";
              organizations = [
                "plumworks"
                "plumjam"
              ];
              token_file = secrets."gradient-server/worker-token".path;
              created_by = "plumjam";
            };
            plum = {
              worker_id = "78ac9597-56e3-4526-a2cf-3cc295c6c80f";
              organizations = [
                "plumworks"
                "plumjam"
              ];
              token_file = secrets."gradient-server/worker-token".path;
              created_by = "plumjam";
            };
          };

          caches = {
            plumworks = {
              active = true;
              name = "plumworks-cache";
              display_name = "PlumWorks Cache";
              max_storage_gb = 50;
              signing_key_file = secrets."gradient-server/cache-signing-key".path;
              organizations = singleton "plumworks";
              created_by = "plumjam";
              inherit upstreams;
            };

            plumjam = {
              active = true;
              name = "plumjam-cache";
              display_name = "PlumJam Cache";
              max_storage_gb = 50;
              signing_key_file = secrets."gradient-server/cache-signing-key".path;
              organizations = singleton "plumjam";
              created_by = "plumjam";
              inherit upstreams;
            };
          };

          users.plumjam = {
            name = "PlumJam";
            email = "ci@plumj.am";
            password_file = secrets."gradient-server/user-plumjam-password".path;
            superuser = true;
            email_verified = true;
          };

          organizations = {
            plumworks = {
              display_name = "PlumWorks";
              description = "PlumWorks";
              created_by = "plumjam";
              private_key_file = secrets."gradient-server/org-plumworks-ssh-private-key".path;
              public = false;
            };

            plumjam = {
              display_name = "PlumJam";
              description = "PlumJam";
              created_by = "plumjam";
              # TODO: make separate one.
              private_key_file = secrets."gradient-server/org-plumworks-ssh-private-key".path;
              public = false;
            };
          };

          projects = {
            grove = {
              active = true;
              name = "grove";
              created_by = "plumjam";
              organization = "plumworks";
              repository = "https://gerrit.plumj.am/grove";
              concurrency = "all";
            };

            nixos = {
              active = true;
              name = "nixos";
              created_by = "plumjam";
              organization = "plumjam";
              repository = "https://git.plumj.am/plumjam/nixos";
              wildcard = "checks.x86_64-linux.*";
              concurrency = "all";
              triggers = singleton {
                type = "reporter_push";
                integration = "git.plumj.am-inbound";
                config = {
                  branches = singleton "master";
                  tags = [ ];
                  releases_only = false;
                };
              };
              actions = singleton {
                name = "report-status";
                type = "forge_status_report";
                config = {
                  integration = "git.plumj.am-outbound";
                };
              };
            };
          };

          integrations = {
            git-plumj-am-inbound = {
              name = "git.plumj.am-inbound";
              display_name = "git.plumj.am-inbound";
              kind = "inbound";
              forge_type = "forgejo";
              secret_file = secrets."gradient-server/forgejo-webhook-hmac-secret".path;
              organization = "plumjam";
              created_by = "plumjam";
            };
            git-plumj-am-outbound = {
              name = "git.plumj.am-outbound";
              display_name = "git.plumj.am-outbound";
              kind = "outbound";
              forge_type = "forgejo";
              endpoint_url = "https://git.plumj.am";
              access_token_file = secrets."gradient-server/forgejo-webhook-access-token".path;
              organization = "plumjam";
              created_by = "plumjam";
            };
          };
        };

        enableQuic = true;
        reverseProxy.nginx.enable = false; # Doing it myself.
      };

      # Only expose websocket on tailscale interface (ts0).
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -i ts0 -p tcp --dport ${toString port} -j nixos-fw-accept
        ip6tables -A nixos-fw -i ts0 -p tcp --dport ${toString port} -j nixos-fw-accept
      '';

      services.nginx.virtualHosts."gradient.${domain}" = merge config.services.nginx.sslTemplate {
        http2 = true;
        http3 = true;
        locations = {
          "/" = {
            root = "${config.services.gradient.packages.frontend}/share/gradient-frontend";
            tryFiles = "$uri $uri/ /index.html";
          };
          "/api/" = {
            proxyPass = "http://${listenAddr}:${toString port}";
            proxyWebsockets = true;
          };

          "/cache/" = {
            proxyPass = "http://${listenAddr}:${toString port}";
            proxyWebsockets = true;
          };

          # "/proto/" not proxied, builders communicate via tailscale network.
        };
      };
    };

  flake.modules.nixos.gradient-worker =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.networking) hostName;
      inherit (config.sops) secrets;

      gradientHostName = "sloe";
      gradientHost = "${gradientHostName}.taild29fec.ts.net";
      gradientPort = 8018;
    in
    {
      imports = singleton inputs.gradient.nixosModules.default;

      sops.secrets = {
        "gradient-worker/token".sopsFile = ../secrets/services/gradient.yaml;
        "gradient-worker/peers".sopsFile = ../secrets/services/gradient.yaml;
      };

      services.gradient.worker = {
        enable = true;

        # Tailscale should optimise if host is the same, I think.
        serverUrl = "ws://${gradientHost}:${toString gradientPort}/proto";

        peersFile = secrets."gradient-worker/peers".path;
        workerId =
          if hostName == "sloe" then
            "019ebc40-e764-72a0-816e-09e490f44995"
          else if hostName == "date" then
            "e652ec89-5784-44ed-bbb8-79adbc4f1d0d"
          else if hostName == "plum" then
            "78ac9597-56e3-4526-a2cf-3cc295c6c80f"
          else
            "";

        capabilities = {
          fetch = true;
          eval = true;
          build = true;
        };

        settings = {
          maxConcurrentBuilds = config.systemInfo.cores;
          evalWorkers = config.systemInfo.cores;
          maxConcurrentEvaluations = config.systemInfo.cores;
          maxNixdaemonConnections = config.systemInfo.cores * 10; # Needs to fit at least * 8.
          buildMetrics = true;
          systemFeatures = [
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
            "uid-range" # For nspawn vm tests.
          ];
        };
      };

      # 1. Using tack for inputs causes `getFlake` to fail in evaluation step - needs impure.
      # 2. Disable distributed builds.
      # 3. Fallback to prevent unnecessary failures.
      systemd.services.gradient-worker.environment.NIX_CONFIG = ''
        pure-eval = false
        builders = ""
        fallback = true
      '';
    };

  flake.modules.nixos.gradient-deploy = { };
}
