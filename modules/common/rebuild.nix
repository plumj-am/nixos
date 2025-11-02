{ pkgs, config, lib, ... }: let
  inherit (lib) mkIf;

  rebuildScript = pkgs.writeScriptBin "rebuild" /* nu */ ''
    #!${pkgs.nushell}/bin/nu

    def print-notify [message: string, progress: int = -1] {
      print $"(ansi purple)[Rebuilder](ansi rst) ($message)"

      let is_error = ($message | str downcase | str contains "error")
      let urgency = if $is_error { "critical" } else { "normal" }

      let timeout = 5000

      let args = if $progress >= 0 and $progress < 100 {
        ["--hint" $"int:value:($progress)"]
      } else {
        []
      }

      ^${pkgs.libnotify}/bin/notify-send ...$args --urgency=($urgency) --expire-time=($timeout) "Rebuilder" $"($message)"
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
  '';
in {
  home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    xdg.desktopEntries.rebuild = {
      name     = "Rebuild";
      icon     = "system-run";
      exec     = ''rebuild'';
      terminal = false;
    };
    xdg.desktopEntries.rebuild-plum = {
      name     = "Rebuild plum";
      icon     = "system-run";
      exec     = ''rebuild --remote plum'';
      terminal = false;
    };
    xdg.desktopEntries.rebuild-kiwi = {
      name     = "Rebuild kiwi";
      icon     = "system-run";
      exec     = ''rebuild --remote kiwi'';
      terminal = false;
    };
    xdg.desktopEntries.rollback = {
      name     = "Rollback";
      icon     = "folder";
      exec     = ''rebuild rollback'';
      terminal = false;
    };
  }];

  environment.systemPackages = [
    rebuildScript
  ];
}
