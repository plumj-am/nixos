{
  config.flake.modules.nixosModules.tailscale =
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

  config.flake.modules.darwinModules.tailscale =
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
}
