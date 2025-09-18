{ ... }: {
  home-manager.sharedModules = [{
    home.file."rebuild.nu" = {
      executable = true;
      text = /* nu */ ''
        #!/usr/bin/env nu

        def --wrapped main [
          host: string = ""    # The host to build (maybe useless will see)
          --remote             # Deploy to remote host using --target-host
          --rollback           # Rollback
          ...arguments         # Extra arguments to pass to rebuild commands
        ]: nothing -> nothing {
          let host = if ($host | is-not-empty) {
            if $host != (hostname) and not $remote {
              print $"(ansi yellow_bold)warn:(ansi reset) building local configuration for hostname that does not match the local machine"
            }
            $host
          } else if $remote {
            print $"(ansi red_bold)error:(ansi reset) hostname not specified for remote deployment"
            exit 1
          } else {
            (hostname)
          }

          # Build locally (always)
          let os = (uname | get kernel-name)
          let config_path = if $os == "Darwin" { "/Users/jam/nixos-config" } else { "/home/jam/nixos-config" }
          let flake_ref = $"($config_path)#($host)"

          let base_args = [
            "switch"
            "--flake" $flake_ref
            "--accept-flake-config" # avoid asking for y/n approval for all settings
          ] | append $arguments

          # Add target-host for remote deployments
          let final_args = if $remote {
            $base_args | append ["--target-host" $"root@($host)"]
          } else {
            $base_args
          }

          # Add rollback flag if specified
          let final_args = if $rollback {
            $final_args | prepend "--rollback"
          } else {
            $final_args
          }

          # Handle Darwin/Linux
          if $os == "Darwin" {
            let action = if $remote { $"deploying to ($host)" } else { "building locally" }
            print $"(ansi green_bold)($action) Darwin configuration for ($host)...(ansi reset)"
            if $remote {
              darwin-rebuild ...$final_args
            } else {
              sudo darwin-rebuild ...$final_args
            }
          } else {
            let action = if $remote { $"deploying to ($host)" } else { "building locally" }
            print $"(ansi green_bold)($action) NixOS configuration for ($host)...(ansi reset)"
            if $remote {
              nixos-rebuild ...$final_args
            } else {
              sudo nixos-rebuild ...$final_args
            }
          }
        }

        # Rollback wrapper
        def rollback [host: string = ""] {
          main $host --rollback
        }
    '';
    };
  }];
}
