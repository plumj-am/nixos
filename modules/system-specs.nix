{
  flake.modules.nixos.system-specs =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) ints bool;
    in
    {
      options.systemSpecs = {
        cores = mkOption {
          type = ints.between 1 128;
          default = 1;
          description = "Total logical CPU cores on this system";
        };

        speedFactor = mkOption {
          type = ints.between 1 10;
          default = 1;
          description = "Relative speed factor for distributed builds";
        };

        builder.enable = mkOption {
          type = bool;
          default = false;
          description = "Whether this host participates as a distributed Nix builder";
        };

        runner.strong = mkOption {
          type = bool;
          default = false;
          description = "System is powerful enough for heavy CI workloads";
        };
      };
    };
}
