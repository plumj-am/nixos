{
  config.flake.modules.nixosModules.boot =
    {
      boot.tmp.cleanOnBoot = true;

      boot.loader.grub = {
        efiSupport            = true;
        efiInstallAsRemovable = true;
      };
    };
}
