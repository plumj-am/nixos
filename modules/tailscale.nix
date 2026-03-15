{
  flake.modules.nixos.tailscale =
    { config, ... }:
    let
      interface = "ts0";
      domains = [ "taild29fec.ts.net" ];
    in
    {
      age.secrets.tailscaleAuthKey.rekeyFile = ../secrets/tailscale-auth-key.age;

      services.resolved.settings.Resolve.Domains = domains;
      services.tailscale = {
        enable = true;

        authKeyFile = config.age.secrets.tailscaleAuthKey.path;

        useRoutingFeatures = "both";
        interfaceName = interface;
      };
    };

  flake.modules.darwin.tailscale = {
    services.tailscale.enable = true;
  };
}
