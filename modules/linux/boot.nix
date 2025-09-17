{ lib, config, ... }: let
  inherit (lib) mkIf;
in {
  boot.loader.grub = mkIf config.isServer {
    efiSupport            = true;
    efiInstallAsRemovable = true;
  };
}
