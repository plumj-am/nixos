{ self, ... }:
{
  flake.modules.nixos.swapfile = self.modules.nixos.swapfile-options;
  flake.modules.nixos.swapfile-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionNullOr mkOptionOf;
      inherit (lib.types) int str;
    in
    {
      options.systemInfo.disks = {
        swap = {
          file = {
            path = mkOptionOf str {
              default = "/swapfile";

            };
            size = mkOptionNullOr int;
          };
        };
      };
    };

  flake.modules.nixos.swap-partition = self.modules.nixos.swap-partition-options;
  flake.modules.nixos.swap-partition-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) str;
    in
    {
      options.systemInfo.disks = {
        swap.partition = {
          size = mkOptionOf str {
            default = "34G";
          };
          path = mkOptionOf str {
            default = "/dev/disk/by-label/swap";
          };
        };
        diskDevice = mkOptionOf str {
          default = "/dev/nvme0n1";
        };
      };
    };
}
