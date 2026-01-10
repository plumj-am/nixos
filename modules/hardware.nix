{
  config.flake.modules.nixos.hardware-desktop =
    { modulesPath, pkgs, ... }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      services.blueman.enable = true;


      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        grub.device = "nodev";
      };

      # Hardware-specific kernel modules
      boot.initrd.availableKernelModules = [
        "ahci"
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];

      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [
        {
          device = "/dev/disk/by-label/SWAP";
        }
      ];

      environment.systemPackages = [
        pkgs.lshw # Hardware info.
        pkgs.usbutils # USB device info.
        pkgs.pciutils # PCI device info.
      ];
    };

  # TODO
  config.flake.modules.nixos.hardware-server =
    { modulesPath, ... }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        grub.device = "nodev";
      };

      # Hardware-specific kernel modules
      boot.initrd.availableKernelModules = [
        "ahci"
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];
    };
}
