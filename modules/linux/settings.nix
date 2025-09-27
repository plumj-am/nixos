{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktopNotWsl {
  networking.networkmanager = enabled {
    wifi.powersave = false;
  };
  users.users.jam.extraGroups = [ "networkmanager" ];

  # Bluetooth support.
  hardware.bluetooth = enabled {
    powerOnBoot = true;
  };
  services.blueman = enabled;

  environment.systemPackages = [
    pkgs.lshw     # Hardware info.
    pkgs.usbutils # USB device info.
    pkgs.pciutils # PCI device info.
  ];

  # Network manager
  programs.nm-applet = enabled;
}
