{
  flake.modules.nixos.swapfile =
    { lib, config, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.options) mkOption;
      inherit (lib.types) int str;

      cfg = config.systemInfo.disks;
    in
    {
      options.systemInfo.disks = {
        swap = {
          file = {
            path = mkOption {
              type = str;
              default = "/swapfile";

            };
            size = mkOption {
              type = int;
              default = null;
            };
          };
        };
      };

      config = {
        boot.zswap.enable = true;
        swapDevices = singleton {
          device = cfg.swap.file.path;
          size = cfg.swap.file.size;
        };
      };
    };
  flake.modules.nixos.swap-partition =
    { lib, config, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.options) mkOption;
      inherit (lib.types) str;

      cfg = config.systemInfo.disks;
    in
    {
      options.systemInfo.disks = {
        swap.partition = {
          size = mkOption {
            type = str;
            default = "34G";
          };
          path = mkOption {
            type = str;
            default = "/dev/disk/by-label/swap";
          };
        };
        diskDevice = mkOption {
          type = str;
          default = "/dev/nvme0n1";
        };
      };

      config = {
        boot.zswap.enable = true;
        swapDevices = singleton {
          device = cfg.swap.partition.path;
        };
      };
    };
}
