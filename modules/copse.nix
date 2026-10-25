{ self, ... }:
{
  flake.modules.common.default = self.modules.common.copse;
  flake.modules.common.copse =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
    in
    {
      environment.systemPackages =
        singleton
          inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.copse;

      hjemModule = {
        xdg.config.files."copse/copse.toml" = {
          generator = pkgs.writers.writeTOML "copse-copse.toml";
          value = {
            max_jobs = 1;
            nice = 10; # CPU niceness for direct-spawn jobs.
            scope = false; # Run jobs inside `systemd-run --user --scope` by default.

            log_height_percent = 50;

            shell = "${getExe pkgs.nushell}";

            grace_secs = 10; # Between SIGTERM and SIGKILL when a job is cancelled.
            notify = true;

            log_tail_bytes = 65536;
            max_env_bytes = 262144;

            retention_days = 7;
            retention_jobs = 300;
          };
        };
      };
    };
}
