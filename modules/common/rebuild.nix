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
          let config_path = if $os == "Darwin" { "/Users/jam/nixos" } else { "/home/jam/nixos" }

          # nh os/darwin switch [flake_path] --hostname [host] -- [nix_args]
          let base_args = [
            "switch"
            $config_path
            "--hostname" $host
            "--accept-flake-config" # avoid asking for y/n approval for all settings
          ] | append $arguments

          # Add target-host for remote deployments
          let final_args = if $remote {
            $base_args | append ["--target-host" $"root@($host)"]
          } else {
            $base_args
          }

          # Handle rollback differently for nh
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

          # Execute nh command
          let action = if $remote { $"deploying to ($host)" } else { "building locally" }
          let platform = if $os == "Darwin" { "Darwin" } else { "NixOS" }
          print $"(ansi green_bold)($action) ($platform) configuration for ($host)...(ansi reset)"

          if $remote {
            NH_BYPASS_ROOT_CHECK=true NH_NO_CHECKS=true nh $command ...$final_args
          } else {
            sudo NH_BYPASS_ROOT_CHECK=true NH_NO_CHECKS=true nh $command ...$final_args
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
