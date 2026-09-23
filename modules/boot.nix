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
  flake.modules.nixos.desktop = self.modules.nixos.boot-systemd;
  flake.modules.nixos.boot-systemd = {
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

  flake.modules.nixos.server = self.modules.nixos.boot-grub;
  flake.modules.nixos.boot-grub =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        bootBase
      ];
      boot.loader.systemd-boot.enable = false;
    };
}
