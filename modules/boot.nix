{
  config.flake.modules.nixos.boot = {
    boot.tmp.cleanOnBoot = true;

    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
