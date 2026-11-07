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
            scope = true; # Run jobs inside `systemd-run --user --scope` by default.

            log_height_percent = 50;

            shell = "${getExe pkgs.nushell}";

            # Source the shell's usual rc file so aliases and functions work.
            # `auto` tries to find a config; "" disables sourcing.
            shell_init = "auto";

            # Keep ANSI colour in tools that disable it when stdout is a pipe.
            force_color = true;

            grace_secs = 10; # Between SIGTERM and SIGKILL when a job is cancelled.

            log_tail_bytes = 65536;
            max_env_bytes = 262144;

            retention_days = 7;
            retention_jobs = 300;

            # Desktop notification when a job finishes (never for cancellations).
            notify = true;
            notification = {
              # States that notify when a job has no `--notify` override.
              states = [
                "succeeded"
                "failed"
                "timed_out"
              ];
              min_duration_secs = 0; # Skip jobs shorter than this.
              coalesce_secs = 0; # 0 sends one per job; 10 batches a burst.
              when_queue_empty = false; # Notify only when the queue drains.
              exclude = ""; # Regex on the job label; a match stays quiet.
              program = "notify-send";
              args = [
                "--app-name=copse"
                "--urgency={urgency}"
                "--expire-time={expire_ms}"
                "{summary}"
                "{body}"
              ];
              summary = "copse: job {id} {state}";
              body = "{name} -- {duration}";
              batch_summary = "copse: {count} jobs finished";
              batch_body = "{ok} ok, {failed} failed";

              urgency = {
                succeeded = "critical";
                failed = "critical";
                timed_out = "critical";
                cancelled = "normal";
              };

              expire_ms = {
                succeeded = 60 * 1000;
                failed = 60 * 1000;
                timed_out = 60 * 1000;
                cancelled = 10 * 1000;
              };
            };
          };
        };
      };
    };
}
