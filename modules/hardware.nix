let
  hardwareDesktop =
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
      ];
    };
in
{
  flake.modules.nixos.hardware-desktop = hardwareDesktop;
}
