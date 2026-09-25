{ self, ... }:
{
  flake.modules.common.headroom =
    {
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton self.services.headroom;

      # Only accept tailscale traffic
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -i ts0 -p tcp --dport 8022 -j nixos-fw-accept
        ip6tables -A nixos-fw -i ts0 -p tcp --dport 8022 -j nixos-fw-accept
      '';

      services.headroom = {
        enable = true;

        port = 8022;
        # Local Vine (both subs). Headroom compresses, then forwards
        # `/v1/chat/completions` to Vine; no `/v1` suffix here.
        openaiApiUrl = "http://127.0.0.1:8023";
      };

      # Headroom binds 127.0.0.Tailscale IP of sloe, so
      # the proxy answers on the tailnet and on no other interface.
      systemd.services.headroom.environment.HEADROOM_HOST = "sloe.taild29fec.ts.net";
    };
}
