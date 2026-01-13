let
  commonModule = {
    boot.loader = {
      efi.canTouchEfiVariables = true;
      grub.device = "nodev";
    };

    boot.initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "xhci_pci"
      "usb_storage"
      "sd_mod"
    ];
  };
in
{
  flake.modules.nixos.boot-desktop =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton commonModule;
      boot.tmp.cleanOnBoot = true;

      boot.loader.systemd-boot.enable = true;
      boot.loader.grub = {
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };

  # TODO?
  flake.modules.nixos.boot-server =
    { modulesPath, ... }:
    {
      imports = [
        commonModule
        (modulesPath + "/installer/scan/not-detected.nix")
      ];
    };
}
