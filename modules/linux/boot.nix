{ lib, config, ... }: let
  inherit (lib) mkIf;
in {
  boot.loader.grub = {
    efiSupport            = true;
    efiInstallAsRemovable = true;
  };
}
