{
  flake.modules.nixos.tailscale =
    { config, ... }:
    let
      inherit (config.sops) secrets;

      interface = "ts0";
      domains = [ "taild29fec.ts.net" ];
    in
    {
      sops.secrets."tailscale/auth-key".sopsFile = ../secrets/services/tailscale.yaml;

      services.resolved.settings.Resolve.Domains = domains;
      services.tailscale = {
        enable = true;

        authKeyFile = secrets."tailscale/auth-key".path;

        useRoutingFeatures = "both";
        interfaceName = interface;
      };
    };

  flake.modules.darwin.tailscale = {
    services.tailscale.enable = true;
  };
}
