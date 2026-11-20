{ self, ... }:
{
  flake.modules.nixos.swapfile = self.modules.nixos.swapfile-options;
  flake.modules.nixos.swapfile-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) int nullOr str;
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
              type = nullOr int;
              default = null;
            };
          };
        };
      };
    };

  flake.modules.nixos.swap-partition = self.modules.nixos.swap-partition-options;
  flake.modules.nixos.swap-partition-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) str;
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
    };
}
