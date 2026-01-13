{
  config.flake.modules.nixos.rebuild =
    { pkgs, ... }:
    let
      rebuildScript = pkgs.writeScriptBin "rebuild" /* nu */ ''
        #!${pkgs.nushell}/bin/nu

        def print-notify [message: string] {
          print $"(ansi purple)[Rebuilder](ansi rst) ($message)"

          ^${pkgs.libnotify}/bin/notify-send "Rebuilder" $"($message)"
        }

        def --wrapped main [
          host: string = ""            # The host to build.
          --remote                     # Deploy to remote host using --target-host.
          --rollback                   # Rollback.
          --quiet (-q)                 # Run without output (for theme toggling).
          --try_attempts (-t): int = 0 # How many times to try the same rebuild.
          ...arguments                 # Extra arguments to pass to rebuild commands.
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
            "--fallback" # Build locally if substituters fail.
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
          if not $quiet { print-notify $"($action) ($platform). Configuration for: ($host)." }

          if $remote {
            for attempts in 1..($try_attempts + 1) {
              try {
                NH_BYPASS_ROOT_CHECK=true NH_NO_CHECKS=true nh $command ...$final_args
                break
              } catch { |e|
                if $attempts < $try_attempts {
                  print-notify $"First attempt failed, retrying... (attempt ($attempts) of ($try_attempts))"
                } else {
                  print-notify $"Error: Rebuild failed after ($try_attempts) attempts, run manually in a terminal."
                  exit 1
                }
              }
            }
          } else {
            for attempts in 1..($try_attempts + 1) {
              try {
                sudo NH_BYPASS_ROOT_CHECK=true NH_NO_CHECKS=true nh $command ...$final_args
                break
              } catch { |e|
                if $attempts < $try_attempts {
                  print-notify $"First attempt failed, retrying... (attempt ($attempts) of ($try_attempts))"
                } else {
                  print-notify $"Error: Rebuild failed after ($try_attempts) attempts, run manually in a terminal."
                  exit 1
                }
              }
            }
          }

          if $rollback {
            if not $quiet { print-notify $"Rollback for ($host) succeeded." }
          } else {
            if not $quiet { print-notify $"Rebuild for ($host) succeeded." }
          }
        }
      '';
    in
    {
      environment.systemPackages = [
        pkgs.nh
        pkgs.nix-output-monitor
        rebuildScript
      ];
    };
}
