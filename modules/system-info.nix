{
  flake.modules.nixos.system-info =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) ints bool;
    in
    {
      options.systemInfo = {
        cores = mkOption {
          type = ints.between 1 128;
          default = 1;
          description = "Total logical CPU cores on this system";
        };

        ciRunner.strong = mkOption {
          type = bool;
          default = false;
          description = "System is powerful enough for heavy CI workloads";
        };
      };
    };
}
