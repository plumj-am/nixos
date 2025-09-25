{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktopNotWsl {
  # NetworkManager for network configuration.
  networking.networkmanager = enabled {
    wifi.powersave = false;
  };

  # Add user to networkmanager group.
  users.users.jam.extraGroups = [ "networkmanager" ];

  # Bluetooth support.
  hardware.bluetooth = enabled {
    powerOnBoot = true;
  };
  services.blueman = enabled;

  # System configuration GUI tools.
  environment.systemPackages = with pkgs; [

    # Network.
    networkmanagerapplet # Network manager system tray.

    # Bluetooth.
    blueman              # Bluetooth manager.

    # System utilities.
    lshw                 # Hardware info.
    usbutils             # USB device info.
    pciutils             # PCI device info.
  ];

  # Enable system tray for network/bluetooth applets.
  programs.nm-applet = enabled;
}
