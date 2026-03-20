{
  flake.modules.nixos.disks-server =
    { lib, inputs, ... }:
    let
      inherit (lib.modules) mkDefault;
    in
    {
      imports = [ inputs.disko.nixosModules.disko ];

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

  flake.modules.nixos.disks-normal =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
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

  flake.modules.nixos.disks-bcachefs =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.options) mkOption;
      inherit (lib.types) str;

      cfg = config.diskConfig;
    in
    {
      imports = singleton inputs.disko.nixosModules.disko;

      config.boot.supportedFilesystems = singleton "bcachefs";

      options.diskConfig = {
        swapSize = mkOption {
          type = str;
          default = "34G";
        };
        diskDevice = mkOption {
          type = str;
          default = "/dev/nvme0n1";
        };
      };

      config.swapDevices = singleton {
        device = "/dev/disk/by-label/swap";
      };

      config.disko.devices = {
        disk.main = {
          device = cfg.diskDevice;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              BOOT = {
                name = "BOOT";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                  extraArgs = "-L BOOT";
                };
              };
              root = {
                name = "root";
                end = "-${cfg.swapSize}";
                content = {
                  type = "filesystem";
                  format = "bcachefs";
                  mountpoint = "/";
                  extraArgs = "--label root";
                };
              };
              swap = {
                name = "swap";
                size = cfg.swapSize;
                content = {
                  type = "swap";
                  discardPolicy = "both";
                  resumeDevice = true;
                  extraArgs = "-L swap";
                };
              };
            };
          };
        };
      };
    };

  flake.modules.nixos.disks-extra-zram-swap = {
    zramSwap.enable = true;
  };
}
