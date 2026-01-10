{
  config.flake.modules.nixos.tailscale =
    let
      interface = "ts0";
      domains = [ "taild29fec.ts.net" ];
    in
    {
      services.resolved.domains = domains;

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
