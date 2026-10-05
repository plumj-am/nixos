{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (lib.meta) getExe;
    in
    {
      packages.rebuild =
        pkgs.writers.writeNuBin "rebuild" # nu
          ''
            def --wrapped main [
               --remote: string # The host to build (defaults to current)
               --help (-h)      # Show this help message
               ...rest: string  # Extra arguments to pass to nh
            ] {
              if $help { help main; exit 0 }

              if "NH_FLAKE" not-in $env { $env.NH_FLAKE = "${self}" }

              let sys = sys host
              let is_nixos = $sys.long_os_version | str lowercase | str contains "linux"
              let hostname = $sys.hostname
              let target = $remote | default $hostname
              let is_remote = $target != $hostname

              # Carry the active theme into plain rebuilds: `os switch` without
              # --specialisation activates the base config, which defaults to
              # light mode and stomps the selected theme.
              let active_theme = if $is_remote { "" } else { get-active-theme }
              let specialisation_args = if ($active_theme == "") {
                []
              } else if ($rest | any {|a| $a | str starts-with "--specialisation"}) {
                []
              } else {
                ["--specialisation" $active_theme]
              }

              let subcommand = if $is_nixos { "os" } else { "darwin" }
              let prefix = if $is_nixos { "nixos" } else { "darwin" }
              let target_host = if $is_remote { ["--target-host" $"root@($target)"] } else { [] }

              let command = [
                ${getExe pkgs.nh}
                $subcommand
                switch
                $"($env.NH_FLAKE)#($prefix)Configurations.($target)"
                --hostname $target
                --accept-flake-config
                --bypass-root-check
                --show-activation-logs
                --builders
                ""
                ...$target_host
                ...$specialisation_args
                ...$rest
              ]

              let is_root = (id -u | str trim) == "0"
              let command = if (not $is_remote) and (not $is_root) {
                $command | prepend ["sudo"]
              } else { $command }

              print $"rebuilding ($target)..."
              try {
                print $"running: ($command)"
                ^($command | first) ...($command | skip 1)
              } catch {
                error make $"rebuilding ($target) failed"
              }

              print $"rebuild for ($target) succeeded."
            }

            # Reads the active theme mode from /etc/theme.json, a build output
            # that always matches the config that is currently running.
            def get-active-theme []: nothing -> string {
              let theme_state = "/etc/theme.json"

              if (not ($theme_state | path exists)) {
                ""
              } else {
                try {
                  open $theme_state | get mode? | default ""
                } catch {|_|
                  ""
                }
              }
            }
          '';
    };
}
