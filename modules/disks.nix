let
  commonModule = {
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };
  };
in
{
  config.flake-file.inputs = {
    disko = {
      url = "github:nix-community/disko";

      inputs.nixpkgs.follows = "os";
    };
  };

  config.flake.modules.nixos.disks-server =
    { lib, inputs, ... }:
    let
      inherit (lib) mkDefault;
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

  config.flake.modules.nixos.disks-desktop = commonModule;

  config.flake.modules.nixos.disks-desktop-swap = {
    imports = [ commonModule ];

    swapDevices = [
      {
        device = "/dev/disk/by-label/SWAP";
      }
    ];
  };

  config.flake.modules.nixos.disks-zram-swap = {
    zramSwap.enable = true;
  };
}
