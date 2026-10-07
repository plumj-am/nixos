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
    in
    {
      # tailscale nginx auth checks the client source address, so nix must
      # reach the cache over the tailnet instead of the public DNS record.
      # Pin sloe's tailnet name so the record resolves before MagicDNS
      # answers during boot.
      networking.hosts = {
        "100.94.223.95" = [
          "graft-cache.plumj.am" # sloe
          "sloe.${tailnet}"
        ];
        "fd7a:115c:a1e0::5401:df8e" = singleton "graft-cache.plumj.am";
      };
    };
}
