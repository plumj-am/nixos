{ self, ... }:
{
  flake.nixosModules.distributed-builds = self.nixosModules.distributed-builds-options;
  flake.nixosModules.distributed-builds-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) ints nullOr;
    in
    {
      options.systemInfo.distributedBuilder.speedFactor = mkOption {
        type = nullOr (ints.between 1 10);
        default = null;
        description = "Relative speed factor for distributed builds";
      };
    };
}
