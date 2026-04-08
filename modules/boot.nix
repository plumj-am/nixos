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
  flake.modules.nixos.boot-systemd = {
    imports = [ bootBase ];
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

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
