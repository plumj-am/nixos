{ self, ... }:
{
  flake.nixosModules.default = self.nixosModules.tailscale;
  flake.nixosModules.tailscale =
    { lib, config, ... }:
    let
      inherit (lib.constants) tailnet;
      inherit (lib.lists) singleton;
      inherit (config.sops) secrets;

      interface = "ts0";
    in
    {
      sops.secrets."tailscale/auth-key".sopsFile = ../secrets/services/tailscale.yaml;

      services.resolved.settings.Resolve.Domains = tailnet;
      services.tailscale = {
        enable = true;

        authKeyFile = secrets."tailscale/auth-key".path;

        useRoutingFeatures = "both";
        interfaceName = interface;
      };

      networking.firewall.trustedInterfaces = singleton interface;
    };

  flake.darwinModules.default = self.darwinModules.tailscale;
  flake.darwinModules.tailscale = {
    services.tailscale.enable = true;
  };
}
