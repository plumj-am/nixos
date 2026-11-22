{ self, ... }:
let
  bootBase = {
    boot = {
      tmp.cleanOnBoot = true;
      loader.grub = {
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      initrd.availableKernelModules = [
        "ahci"
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];
    };
  };
in
{
  flake.nixosModules.desktop = self.nixosModules.boot-systemd;
  flake.nixosModules.boot-systemd = {
    imports = [ bootBase ];
    boot.loader = {
      timeout = 1;
      systemd-boot = {
        enable = true;
        configurationLimit = 20;
        bootCounting.enable = true;
      };

      efi.canTouchEfiVariables = true;
    };
  };

  flake.nixosModules.server = self.nixosModules.boot-grub;
  flake.nixosModules.boot-grub =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        bootBase
      ];
      boot.loader.systemd-boot.enable = false;
    };
}
