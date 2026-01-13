{
  flake.modules.nixos.network =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.types)
        listOf
        nullOr
        str
        int
        either
        ;
      inherit (lib.options) mkOption;
      inherit (lib) mkDefault;
    in
    {
      # Named "network" to avoid conflicts with the "networking" options.
      # Not sure if it would even be a problem but oh well.
      options.network = {

        hostName = mkOption {
          type = str;
          example = "yuzu";
          description = "Host's unique name";
        };

        interfaces = mkOption {
          type = listOf str;
          example = [ "ts0" ];
          default = [ "ts0" ];
          description = "Network interfaces";
        };

        domain = mkOption {
          type = nullOr str;
          default = null;
          example = "example.com";
          description = "Network domain (optional)";
        };

        tcpPorts = mkOption {
          type = listOf (either int str);
          default = [ 22 ];
          example = [
            22
            80
            443
          ];
          description = "TCP ports to allow through the firewall";
        };
      };

      config = {
        networking.networkmanager = {
          enable = true;
          wifi.powersave = false;
        };
        programs.nm-applet.enable = true;
        users.users.jam.extraGroups = [ "networkmanager" ];

        networking.hostName = config.network.hostName;

        networking.domain = mkIf (config.network.domain != null) config.network.domain;

        networking.firewall = {
          enable = true;
          trustedInterfaces = config.network.interfaces;
          allowedTCPPorts = config.network.tcpPorts;
        };

        networking.useDHCP = mkDefault true;
        networking.interfaces = { };
      };
    };

  flake.modules.darwin.network =
    { config, lib, ... }:
    let
      inherit (lib.types) str;
      inherit (lib.options) mkOption;
    in
    {
      # Named "network" to avoid conflicts with the "networking" options.
      # Not sure if it would even be a problem but oh well.
      options.network = {
        hostName = mkOption {
          type = str;
          example = "yuzu";
          description = "Host's unique name";
        };
      };

      config.networking.hostName = config.network.hostName;
    };
}
