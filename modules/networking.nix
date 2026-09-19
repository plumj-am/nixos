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

        settings.connection = {
          "wifi.cloned-mac-address" = "stable";
          "ethernet.cloned-mac-address" = "stable";
          "connection.stable-id" = "\${CONNECTION}/\${BOOT}";
          "ipv4.dhcp-send-hostname" = "false";
        };
      };
      programs.nm-applet.enable = true;
      users.users.jam.extraGroups = singleton "networkmanager";

      networking.firewall.enable = true;

      networking.useDHCP = mkDefault true;
      networking.interfaces = { };
    };
}
