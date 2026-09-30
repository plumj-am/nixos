{ self, ... }:
{
  flake.modules.nixos.system-info = self.modules.nixos.system-info-options;
  flake.modules.nixos.system-info-options =
    { lib, config, ... }:
    let
      inherit (lib.lists) elemAt;
      inherit (lib.options) mkOptionOf;
      inherit (lib.types)
        bool
        int
        nullOr
        str
        ;
      inherit (config.hardware.facter) report;

      cpu = if (report != { }) then elemAt report.hardware.cpu 0 else { };
      cores = cpu.cores or 4;
      threads = cpu.siblings or 4;

      gpu = elemAt report.hardware.graphics_card 0;
      gpuExists = gpu != [ ];
      gpuVendor = gpu.vendor.name;
    in
    {
      options.systemInfo = {
        cores = mkOptionOf int {
          default = cores;
          readOnly = true;
          description = "CPU cores derived from facter report";

        };
        threads = mkOptionOf int {
          default = threads;
          readOnly = true;
          description = "CPU threads derived from facter report";
        };
        gpu = {
          exists = mkOptionOf bool {
            default = gpuExists;
            readOnly = true;
            description = "GPU existence derived from facter report";
          };
          vendor = mkOptionOf (nullOr str) {
            default = gpuVendor;
            readOnly = true;
            description = "GPU vendor derived from facter report";
          };
        };
      };
    };
}
