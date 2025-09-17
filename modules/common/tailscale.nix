{ lib, ... }: let
  inherit (lib) enabled;

  interface = "ts0";
in {
  services.resolved.domains = ["taild29fec.ts.net"];

  services.tailscale = enabled {
    useRoutingFeatures = "both";
    interfaceName      = interface;
  };
}
