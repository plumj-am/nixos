{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.networking;
  flake.modules.nixos.networking =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkDefault;
    in
    {
      networking.networkmanager = {
        enable = true;
        wifi.powersave = false;
      };

      programs.nm-applet.enable = true;
      users.users.jam.extraGroups = singleton "networkmanager";

      networking.firewall.enable = true;

      networking.useDHCP = mkDefault true;
      networking.interfaces = { };
    };

  flake.modules.nixos.dynamic-mac-address = {
    networking.networkmanager.settings.connection = {
      "wifi.cloned-mac-address" = "stable";
      "ethernet.cloned-mac-address" = "stable";
      "connection.stable-id" = "\${CONNECTION}/\${BOOT}";
      "ipv4.dhcp-send-hostname" = "false";
    };
  };

  flake.modules.common.default = self.modules.common.hosts;
  flake.modules.common.hosts =
    { lib, ... }:
    let
      inherit (lib.constants) tailnet;
      inherit (lib.lists) singleton;

      graftCache = "graft-cache.${tailnet}";
    in
    {
      networking.hosts = {
        "100.127.89.136" = singleton graftCache;
        "fd7a:115c:a1e0::a839:5989" = singleton graftCache;

        "100.94.223.95" = singleton "sloe.${tailnet}";
      };
    };
}
