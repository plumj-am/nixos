{ config, lib, ... }: let
  inherit (lib) mkIf;
in {
  home-manager.sharedModules = [{
    xdg.desktopEntries.rebuild = mkIf config.isDesktopNotWsl {
      name     = "Rebuild";
      exec     = ''nu /home/jam/rebuild.nu'';
      terminal = false;
    };
    xdg.desktopEntries.rebuild-plum = mkIf config.isDesktopNotWsl {
      name     = "Rebuild plum";
      exec     = ''nu /home/jam/rebuild.nu --remote plum'';
      terminal = false;
    };
    xdg.desktopEntries.rebuild-kiwi = mkIf config.isDesktopNotWsl {
      name     = "Rebuild kiwi";
      exec     = ''nu /home/jam/rebuild.nu --remote kiwi'';
      terminal = false;
    };
    xdg.desktopEntries.rollback = mkIf config.isDesktopNotWsl {
      name     = "Rollback";
      exec     = ''nu /home/jam/rebuild.nu --rollback'';
      terminal = false;
    };
    home.file."rebuild.nu" = mkIf config.isDesktop {
      executable = true;
      text = /* nu */ ''
        #!/usr/bin/env nu
        def print-notify [message: string, progress: int = -1] {
          print $"(ansi purple)[Rebuilder] ($message)"
          if (which dunstify | is-not-empty) {
            let base_args = ["--appname=Rebuilder" "--replace=1003"]
            let args = if $progress >= 0 {
              $base_args | append ["--hints" $"int:value:($progress)"]
            } else {
              $base_args
            }

            # Use persistent notifications (timeout=0) when in-progress.
            # Use short timeout for completion messages (progress=100).
            let timeout = if $progress >= 0 and $progress < 100 { 0 } else { 15000 }

            if ($message | str downcase | str contains "error") {
              ^dunstify ...$args --urgency=critical --timeout=30000 "Rebuilder" $"($message)"
            } else {
              ^dunstify ...$args --urgency=normal --timeout=($timeout) "Rebuilder" $"($message)"
            }
          }
        }

        def --wrapped main [
          host: string = ""    # The host to build.
          --remote             # Deploy to remote host using --target-host.
          --rollback           # Rollback.
          --quiet              # Run without output (for theme toggling).
          ...arguments         # Extra arguments to pass to rebuild commands.
        ]: nothing -> nothing {
          let host = if ($host | is-not-empty) {
            if $host != (hostname) and not $remote {
              if not $quiet { print-notify $"Error: Building local configuration for hostname that does not match the local machine." }
              exit 1
            }
            $host
          } else if $remote {
            if not $quiet { print-notify "Error: Hostname not specified for remote deployment." }
            exit 1
          } else {
            (hostname)
          }

          # Build locally (always).
          let os = (uname | get kernel-name)
          let config_path = if $os == "Darwin" { "/Users/jam/nixos" } else { "/home/jam/nixos" }

          # nh os/darwin switch [flake_path] --hostname [host] -- [nix_args]
          let base_args = [
            "switch"
            $config_path
            "--hostname" $host
            "--accept-flake-config" # Avoid asking for y/n approval for all settings.
          ] | append $arguments

          # Add target-host for remote deployments.
          let final_args = if $remote {
            $base_args | append ["--target-host" $"root@($host)"]
          } else {
            $base_args
          }

          let command = if $rollback {
            "rollback"
          } else {
            if $os == "Darwin" { "darwin" } else { "os" }
          }

          let final_args = if $rollback {
            [$host] | append $arguments
          } else {
            $final_args
          }

          # Execute final command.
          let action = if $remote { $"Deploying to: ($host)" } else { "Building locally:" }
          let platform = if $os == "Darwin" { "Darwin" } else { "NixOS" }
          if not $quiet { print-notify $"($action) ($platform). Configuration for: ($host)." 50 }

          try {
            nh $command ...$final_args
          } catch { |e|
            if not $quiet { print-notify "Error: Rebuild failed, run manually in a terminal." }
            exit 1
          }

          if $rollback {
            if not $quiet { print-notify $"Rollback for ($host) succeeded." 100 }
          } else {
            if not $quiet { print-notify $"Rebuild for ($host) succeeded." 100 }
          }
        }

        # Rollback wrapper.
        def rollback [host: string = ""] {
          main $host --rollback
        }
    '';
    };
  }];
}
