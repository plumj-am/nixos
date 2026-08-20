{
  flake.modules.nixos.hardware-desktop =
    { pkgs, ... }:
    {
      hardware = {
        enableRedistributableFirmware = true; # Fixes iwlwifi firmware.
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
      };
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
