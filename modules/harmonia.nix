{
  flake.modules.nixos.harmonia =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) filter singleton;
      inherit (lib.modules) mkIf;
      inherit (config.age) secrets;
      inherit (config.networking) hostName;

      port = 5000;

      hosts = [
        "plum"
        "kiwi"
        # "blackwell"
        "sloe"
        "date"
        # "pear"
        "yuzu"
      ];
    in
    {
      services.harmonia.cache = {
        enable = true;
        signKeyPaths = mkIf (secrets ? nixStoreKey) <| singleton secrets.nixStoreKey.path;
        settings = {
          bind = "[::]:${toString port}";
          workers = 4;
          max_connection_rate = 256;
          priority = 42;
          # Lower priority than nix-community.cachix.org so we only fallback to our
          # slower caches if necessary.
        };
      };

      # Only expose harmonia on tailscale interface (ts0).
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -i ts0 -p tcp --dport ${toString port} -j nixos-fw-accept
        ip6tables -A nixos-fw -i ts0 -p tcp --dport ${toString port} -j nixos-fw-accept
      '';

      nix.settings = {
        trusted-users = [ "harmonia" ];
        extra-substituters =
          map (h: "http://${h}.taild29fec.ts.net:${toString port}") <| filter (h: h != hostName) hosts;
        # TODO: dedupe here and ./object-storage.nix.
        trusted-public-keys = [
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
