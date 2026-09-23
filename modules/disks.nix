{ self, ... }:
{
  flake.modules.nixos.server = self.modules.nixos.disks-server;
  flake.modules.nixos.disks-server =
    { inputs, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkDefault;
    in
    {
      imports = singleton inputs.disko.nixosModules.disko;

      services.fstrim.enable = true;

      disko.devices = {
        disk.disk1 = {
          device = mkDefault "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                name = "boot";
                size = "1M";
                type = "EF02";
              };
              esp = {
                name = "ESP";
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              root = {
                name = "root";
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
              };
            };
          };
        };
        lvm_vg = {
          pool = {
            type = "lvm_vg";
            lvs = {
              root = {
                size = "100%FREE";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = [ "defaults" ];
                };
              };
            };
          };
        };
      };
    };

  flake.modules.nixos.desktop = self.modules.nixos.disks-normal;
  flake.modules.nixos.disks-normal =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      services.fstrim.enable = true;

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/root";
          fsType = "ext4";
        };
      };

      swapDevices = singleton {
        device = "/dev/disk/by-label/swap";
      };
    };
}
