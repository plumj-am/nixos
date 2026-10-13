{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.hardware-desktop;
  flake.modules.nixos.hardware-desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (config.networking) hostName;
    in
    {
      hardware = {
        enableRedistributableFirmware = true; # Fixes iwlwifi firmware.
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
      };

      # No wifi use for yuzu. Blacklisting iwlwifi frees the AX211's shared
      # WLAN/BT antenna -> no coex contention.
      boot.blacklistedKernelModules = mkIf (hostName == "yuzu") [
        "iwlwifi"
        "iwlmvm"
      ];

      services.blueman.enable = true;

      environment.systemPackages = [
        pkgs.lshw # Hardware info.
        pkgs.usbutils # USB device info.
        pkgs.pciutils # PCI device info.

        # iphone trash
        pkgs.libimobiledevice
        pkgs.ifuse
        pkgs.usbmuxd
      ];

      services.usbmuxd.enable = true;
    };
}
