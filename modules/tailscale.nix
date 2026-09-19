{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.tailscale;
  flake.modules.nixos.tailscale =
    { lib, config, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (config.sops) secrets;

      interface = "ts0";
    in
    {
      sops.secrets."tailscale/auth-key".sopsFile = ../secrets/services/tailscale.yaml;

      services.resolved.settings.Resolve.Domains = "taild29fec.ts.net";
      services.tailscale = {
        enable = true;

        authKeyFile = secrets."tailscale/auth-key".path;

        useRoutingFeatures = "both";
        interfaceName = interface;
      };

      networking.firewall.trustedInterfaces = singleton interface;
    };

  flake.modules.darwin.default = self.modules.darwin.tailscale;
  flake.modules.darwin.tailscale = {
    services.tailscale.enable = true;
  };
}
