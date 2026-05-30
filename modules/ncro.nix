{
  flake.modules.nixos.ncro =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.modules) mkForce;
      inherit (lib.trivial) flip;
      inherit (lib.lists) singleton;

      port = "8013";
      ncroUrl = "http://localhost:${port}";

      harmoniaUrl = "taild29fec.ts.net:5000";
      harmoniaHosts = [
        "plum"
        "kiwi"
        "sloe"
        "date"
        "yuzu"
      ];
      harmoniaUpstreams = flip map harmoniaHosts (h: {
        url = "http://${h}.${harmoniaUrl}";
        priority = 30;
      });

      s3Url = "s3://plumjam/nix?endpoint=fsn1.your-objectstorage.com&scheme=https";
    in
    {
      imports = singleton inputs.ncro.nixosModules.default;

      systemd.services.ncro.serviceConfig.Environment = ''
        AWS_EC2_METADATA_DISABLED=true
      '';
      services.ncro = {
        enable = true;
        package = inputs.ncro.packages.${pkgs.system}.ncro;

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
            }
            {
              url = "https://nix-community.cachix.org";
              priority = 20;
            }
            {
              url = "https://cache.garnix.io";
              priority = 25;
            }
            {
              url = s3Url;
              priority = 43;
            }
          ]
          ++ harmoniaUpstreams;

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

          mesh = { };
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
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="

          "yuzu-store.plumj.am:rRhcZfgv1nSDQxDhgzaudcpyl/JtqoEf4QOsPble7S8="
          "yuzu-store.plumj.am:p6zQw/rR/i1GxTNYE9nNMgReiy2PuDwpq6aXW0DKfoo=" # TODO: Remove after 2026-06-01
          "plum-store.plumj.am:LBmfncp/ftlagUEZOM0NWK2tTH4fIT0Bk2WEBU48CNM="
          "kiwi-store.plumj.am:PMlO9Tv8jZf5huFRsKWBD7ejVASjUXnZS1o7xpsN5hw="
          "sloe-store.plumj.am:1qIquG/lWLGgyeyfFBSNuifrNevsGXFf53Bi0stcsxo="
          "date-store.plumj.am:1sziS/y3AiWPV8TY8pHtK3tYxiN10ujutWDNpo4O1Fg="
          "blackwell-store.plumj.am:YmTvW2JngBUxfgWoKHJzxKu7Xhxt4VzK5u3D0Chudn4="
        ];
      };
    };
}
