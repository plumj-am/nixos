let
  commonModule = {
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
  flake.modules.nixos.boot-desktop = {
    imports = [ commonModule ];
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  flake.modules.nixos.boot-server =
    { modulesPath, ... }:
    {
      imports = [
        commonModule
        (modulesPath + "/installer/scan/not-detected.nix")
      ];
    };
}
