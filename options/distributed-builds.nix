{ self, ... }:
{
  flake.modules.nixos.distributed-builds = self.modules.nixos.distributed-builds-options;
  flake.modules.nixos.distributed-builds-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionNullOr;
      inherit (lib.types) ints;
    in
    {
      options.systemInfo.distributedBuilder.speedFactor = mkOptionNullOr (ints.between 1 10) {
        description = "Relative speed factor for distributed builds";
      };
    };
}
