{ self, ... }:
{
  flake.nixosModules.swapfile = self.nixosModules.swapfile-options;
  flake.nixosModules.swapfile-options =
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

  flake.nixosModules.swap-partition = self.nixosModules.swap-partition-options;
  flake.nixosModules.swap-partition-options =
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
