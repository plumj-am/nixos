{
  config.flake.modules.nixos.tailscale =
    let
      interface = "ts0";
      domains = [ "taild29fec.ts.net" ];
    in
    {
      services.resolved.settings.Resolve.Domains = domains;
      services.tailscale = {
        enable = true;

        useRoutingFeatures = "both";
        interfaceName = interface;
      };
    };

  config.flake.modules.darwin.tailscale = {
    services.tailscale.enable = true;
  };
}
