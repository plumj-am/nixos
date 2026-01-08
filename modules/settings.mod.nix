{
  config.flake.modules.nixosModules.settings =
    { pkgs, ... }:
    {
      networking.networkmanager = {
        enable = true;
        wifi.powersave = false;
      };
      users.users.jam.extraGroups = [ "networkmanager" ];

      # Bluetooth support.
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      services.blueman.enable = true;

      environment.systemPackages = [
        pkgs.lshw # Hardware info.
        pkgs.usbutils # USB device info.
        pkgs.pciutils # PCI device info.
      ];

      # Network manager
      programs.nm-applet.enable = true;
    };
}
