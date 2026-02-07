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

  bootSystemd = {
    imports = [ bootBase ];
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  bootGrub =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        bootBase
      ];
      boot.loader.systemd-boot.enable = false;
    };
in
{
  flake.modules.nixos.boot-systemd = bootSystemd;
  flake.modules.nixos.boot-grub = bootGrub;
}
