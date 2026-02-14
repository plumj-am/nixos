{
  flake.modules.nixos.networking =
    { lib, ... }:
    let
      inherit (lib) mkDefault;
    in
    {
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
