{ self, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;
    in
    {
      packages.rebuild =
        pkgs.writers.writeNuBin "rebuild" # nu
          ''
            def --wrapped main [
               --remote: string # The host to build (defaults to current)
               --emacs (-e)     # Also reload emacs
               --help (-h)      # Show this help message
               ...rest: string  # Extra arguments to pass to nh
            ] {
              if $help { help main; exit 0 }

              $env.NH_FLAKE = "${self}"

              let sys = sys host
              let is_nixos = $sys.long_os_version | str lowercase | str contains "linux"
              let hostname = $sys.hostname
              let target = $remote | default $hostname
              let is_remote = $target != $hostname

              let privilege = if $is_remote { [] } else { ["sudo"] }
              let subcommand = if $is_nixos { "os" } else { "darwin" }
              let prefix = if $is_nixos { "nixos" } else { "darwin" }
              let target_host = if $is_remote { ["--target-host" $"root@($target)"] } else { [] }

              let command = [
                $privilege
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
                ...$rest
              ]

              print $"rebuilding ($target)..."
              try {
                ^($command | first) ...($command | skip 1)
              } catch {
                error make $"rebuilding ($target) failed"
              }

              if $emacs { main reload-emacs }

              print $"rebuild for ($target) succeeded."
            }

            def "main reload-emacs" [] {
              print "reloading emacs config..."
              try {
                emacsclient --eval '(load-file "/home/jam/.config/emacs/init.el")' | ignore
              } catch {|e|
                error make $"reloading emacs failed: ($e)"
              }
            }
          '';
    };
}
