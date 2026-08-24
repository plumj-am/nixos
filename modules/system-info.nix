{
  flake.modules.nixos.system-info =
    { lib, config, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types)
        int
        nullOr
        str
        bool
        ;
      inherit (lib.lists) elemAt;
      inherit (config.hardware.facter) report;

      cpu = elemAt report.hardware.cpu 0;
      inherit (cpu) cores;
      threads = cpu.siblings;

      gpu = elemAt report.hardware.graphics_card 0;
      gpuExists = gpu != [ ];
      gpuVendor = gpu.vendor.name;
    in
    {
      options.systemInfo = {
        cores = mkOption {
          type = int;
          default = cores;
          readOnly = true;
          description = "CPU cores derived from facter report";

        };
        threads = mkOption {
          type = int;
          default = threads;
          readOnly = true;
          description = "CPU threads derived from facter report";
        };
        gpu = {
          exists = mkOption {
            type = bool;
            default = gpuExists;
            readOnly = true;
            description = "GPU existence derived from facter report";
          };
          vendor = mkOption {
            type = nullOr str;
            default = gpuVendor;
            readOnly = true;
            description = "GPU vendor derived from facter report";
          };
        };
      };
    };
}
