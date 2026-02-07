{
  flake.modules.nixos.networking =
    { lib, ... }:
    let
      inherit (lib.types) nullOr str;
      inherit (lib.options) mkOption;
      inherit (lib) mkDefault;
    in
    {
      options.network = {
        domain = mkOption {
          type = nullOr str;
          default = null;
          example = "example.com";
          description = "Network domain (optional)";
        };
      };

      config = {
        networking.networkmanager = {
          enable = true;
          wifi.powersave = false;
        };
        programs.nm-applet.enable = true;
        users.users.jam.extraGroups = [ "networkmanager" ];

        networking.firewall = {
          enable = true;
          trustedInterfaces = [ "ts0" ];
          allowedTCPPorts = [ 22 ];
        };

        networking.useDHCP = mkDefault true;
        networking.interfaces = { };
      };
    };
}
