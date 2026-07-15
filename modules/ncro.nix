{
  flake.modules.nixos.ncro =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) mkForce;
      inherit (lib.trivial) flip;
      inherit (lib.lists) singleton filter;
      inherit (config.s3.caches) fsn1 garage;

      port = "8013";
      ncroUrl = "http://localhost:${port}";

      tailnet = "taild29fec.ts.net";
      meshPort = "7946";

      harmoniaUrl = "${tailnet}:5000";
      harmoniaHosts = [
        {
          name = "plum";
          key = "9f193f58b1bf4d35de86471ba3d85f8397dc838c39a93ad08c5dadd4724af7ca";
        }
        {
          name = "kiwi";
          key = "3b8d4ef4b11a643892c16e38efaafe7a5db0dc0c835fa80a211fbe836b7663a7";
        }
        {
          name = "sloe";
          key = "30978780e116e3287e14ba75f459a0be79e13c233a8196283c35a6abdcc569b7";
        }
        {
          name = "date";
          key = "91d83f3e8f3f502c46831e27935bafe9ba25f5551367f8ef443587776ad772f9";
        }
        {
          name = "yuzu";
          key = "9b2e111a6e1e8301638f1e95c022e09c488084146fbbcece24a4bc95ba8fc9b6";
        }
      ];
      harmoniaUpstreams = flip map harmoniaHosts (h: {
        url = "http://${h.name}.${harmoniaUrl}";
        priority = 30;
        nar_url_mode = "keep";
      });

      s3Upstreams = [
        {
          url = "s3://plumjam/nix?endpoint=fsn1.your-objectstorage.com&scheme=https&profile=${fsn1.alias}";
          priority = 43;
          nar_url_mode = "keep";
        }
        {
          url = "s3://nix?endpoint=s3.plumj.am&scheme=https&profile=${garage.alias}&region=${garage.region}";
          priority = 43;
          nar_url_mode = "keep";
        }
      ];
    in
    {
      imports = singleton inputs.ncro.nixosModules.default;

      # S3 credentials come from the shared file materialised by the `s3`
      # aspect (s3-credentials.service at /var/lib/s3/.aws/credentials).
      systemd.services.ncro = {
        serviceConfig = {
          Environment = ''
            AWS_EC2_METADATA_DISABLED=true
          '';
          SupplementaryGroups = [ "s3" ];
        };
        environment.AWS_SHARED_CREDENTIALS_FILE = config.s3.credentialsFile;
      };

      services.ncro = {
        enable = true;
        package = inputs.ncro.packages.${pkgs.stdenv.hostPlatform.system}.ncro;

        settings = {
          server = {
            listen = ":${port}";
            read_timeout = "30s";
            write_timeout = "30s";
          };

          # All upstreams that Nix should source from. ncro races narinfo
          # lookups across these and picks the fastest. NAR streams fall
          # through by latency order.
          upstreams = [
            {
              url = "https://cache.nixos.org";
              priority = 10;
              nar_url_mode = "keep";
            }
            {
              url = "https://nix-community.cachix.org";
              priority = 20;
              nar_url_mode = "keep";
            }
          ]
          ++ s3Upstreams
          ++ harmoniaUpstreams;

          fallback_cache = {
            enabled = true;
            url = "https://cache.nixos.org";
          };

          cache = {
            db_path = "/var/lib/ncro/routes.db";
            max_entries = 100000;
            ttl = "1h";
            negative_ttl = "10m";
            latency_alpha = 0.3;
          };

          logging = {
            level = "info";
            format = "json";
          };

          discovery = { };

          mesh = {
            enabled = true;
            bind_addr = "0.0.0.0:${meshPort}";
            # auto-generated
            private_key = "/var/lib/ncro/mesh.key";
            gossip_interval = "30s";
            peers = map (h: {
              addr = "${h.name}.${tailnet}:${meshPort}";
              public_key = h.key or "";
            }) (filter (h: h != config.networking.hostName) harmoniaHosts);
          };
        };
      };

      nix.settings = {
        # ncro must be the *only* substituter. Override both base and extra
        # lists so that harmonia, s3-upload, and nix-settings extras are
        # replaced.
        substituters = mkForce <| singleton ncroUrl;
        extra-substituters = mkForce [ ];

        # Handle trusted keys manually.
        trusted-public-keys = mkForce [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

          "yuzu-store.plumj.am:rRhcZfgv1nSDQxDhgzaudcpyl/JtqoEf4QOsPble7S8="
          "plum-store.plumj.am:LBmfncp/ftlagUEZOM0NWK2tTH4fIT0Bk2WEBU48CNM="
          "kiwi-store.plumj.am:PMlO9Tv8jZf5huFRsKWBD7ejVASjUXnZS1o7xpsN5hw="
          "sloe-store.plumj.am:1qIquG/lWLGgyeyfFBSNuifrNevsGXFf53Bi0stcsxo="
          "date-store.plumj.am:1sziS/y3AiWPV8TY8pHtK3tYxiN10ujutWDNpo4O1Fg="
          "blackwell-store.plumj.am:YmTvW2JngBUxfgWoKHJzxKu7Xhxt4VzK5u3D0Chudn4="
        ];
      };
    };
}
