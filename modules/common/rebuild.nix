{ config, lib, ... }: let
  inherit (lib) mkIf;
in {
  home-manager.sharedModules = [{
    xdg.desktopEntries.rebuild = mkIf config.isDesktopNotWsl {
      name     = "Rebuild";
      exec     = ''nu /home/jam/rebuild.nu'';
      terminal = false;
    };
    xdg.desktopEntries.rollback = mkIf config.isDesktopNotWsl {
      name     = "Rollback";
      exec     = ''nu /home/jam/rebuild.nu --rollback'';
      terminal = false;
    };
    home.file."rebuild.nu" = {
      executable = true;
      text = /* nu */ ''
        #!/usr/bin/env nu
        def print-notify [message: string] {
            print $"[Rebuild]: ($message)"
            if (which dunstify | is-not-empty) {
                if ($message | str downcase | str contains "error") {
                    ^dunstify --appname="Rebuild" --urgency=critical --timeout=30000 "Error" $"($message)"
                } else {
                    ^dunstify --appname="Rebuild" "Status" $"($message)"
                }
            }
        }

        def --wrapped main [
          host: string = ""    # The host to build.
          --remote             # Deploy to remote host using --target-host.
          --rollback           # Rollback.
          ...arguments         # Extra arguments to pass to rebuild commands.
        ]: nothing -> nothing {
          let host = if ($host | is-not-empty) {
            if $host != (hostname) and not $remote {
              print-notify $"Error: Attempted to build local configuration for hostname that does not match the local machine."
              exit 1
            }
            $host
          } else if $remote {
            print-notify $"Error: Hostname not specified for remote deployment."
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

          # Add target-host for remote deployments
          let final_args = if $remote {
            $base_args | append ["--target-host" $"root@($host)"]
          } else {
            $base_args
          }

          # Handle rollback differently for nh.
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

          # Execute nh command.
          let action = if $remote { $"Deploying to ($host): " } else { "Building locally:" }
          let platform = if $os == "Darwin" { "Darwin" } else { "NixOS" }
          print-notify $"($action) ($platform) configuration for ($host)..."

          if $remote {
            try {
              NH_BYPASS_ROOT_CHECK=true NH_NO_CHECKS=true nh $command ...$final_args
            } catch { |e|
              print-notify "An error occurred during the rebuild. Run `rebuild` manually."
            }
          } else {
            try {
              sudo NH_BYPASS_ROOT_CHECK=true NH_NO_CHECKS=true nh $command ...$final_args
            } catch { |e|
              print-notify "An error occurred during the rebuild. Run `rebuild` manually."
            }
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
