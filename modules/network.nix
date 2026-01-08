{ config, lib, ... }: let
  inherit (lib) enabled mkIf types;
in {
  # Named "network" to avoid conflicts with the "networking" options.
  # Not sure if it would even be a problem but oh well.
  options.network = {
    enable = lib.mkEnableOption "network";

    hostName = lib.mkOption {
      type = types.str;
      example = "yuzu";
      description = "Host's unique name";
    };

    interfaces = lib.mkOption {
      type = with types; listOf str;
      example = [ "ts0" ];
      default = [ "ts0" ];
      description = "Network interfaces";
    };

    domain = lib.mkOption {
      type = with types; nullOr str;
      default = null;
      example = "example.com";
      description = "Network domain (optional)";
    };

    tcpPorts = lib.mkOption {
      type = with types; listOf (either int str);
      default = [ 22 ];
      example = [ 22 80 443 ];
      description = "TCP ports to allow through the firewall";
    };
  };

  config = {
    networking.hostName = config.network.hostName;

    networking.domain = mkIf (config.network.domain != null) config.network.domain;

    networking.firewall = enabled {
      trustedInterfaces = config.network.interfaces;
      allowedTCPPorts   = config.network.tcpPorts;
    };

    networking.useDHCP    = lib.mkDefault true;
    networking.interfaces = {};
  };
}
