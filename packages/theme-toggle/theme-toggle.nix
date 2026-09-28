{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (lib.meta) getExe;

      rebuildScript = getExe self.packages.${pkgs.stdenv.hostPlatform.system}.rebuild;

      toggleTheme =
        pkgs.writers.writeNuBin "toggle-theme" # nu
          ''
            let NIXOS_CONFIG = $"($env.HOME)/nixos"
            let THEME_STATE = "/etc/theme.json"

            def update-gsettings []: any -> nothing {
              let scheme = if ((get-current-theme).mode == "dark") { "prefer-dark" } else { "prefer-light" }

              try {
                dconf write /org/gnome/desktop/interface/color-scheme $"'($scheme)'"
              } catch {|e|
                print --stderr $"failed to save theme via dconf: ($e)"
              }
            }

            def get-current-theme []: any -> record<mode: string> {
              try {
                open $THEME_STATE
              } catch {
                print --stderr $"Failed to read ($THEME_STATE), falling back to dark"

                {mode: dark}
              }
            }

            def refresh-apps [apps: list<record<name: string, signal: string>>] {
              $apps | par-each {|app|
                if (pkill $"-($app.signal)" $app.name | complete | get exit_code) > 1 {
                  print --stderr $"Failed to reload ($app.name)"
                }
              }
            }

            def reload-applications []: nothing -> nothing {
              print "Reloading applications..."

              let refreshable_apps = [
                {name: "hx", signal: "USR1"}
                {name: "opencode", signal: "USR2"}
              ]

              [
                {
                  if (qs --no-duplicate -p /home/jam/nixos/modules/quickshell/shell ipc call shell reload | complete | get exit_code) != 0 {
                    print --stderr "Failed to reload quickshell"
                  }
                }
                {
                  if (herdr server reload-config | complete | get exit_code) != 0 {
                    print --stderr "Failed to reload herdr"
                  }
                }
                { refresh-apps $refreshable_apps }
                { update-gsettings }
              ] | par-each {|f| do $f}

              print "Application reloading complete."
            }

            def switch-variant [mode: string]: nothing -> nothing {
              let name = $mode
              print $"Switching to the ($name) theme."

              try {
                sudo env $"NH_FLAKE=($NIXOS_CONFIG)" ${rebuildScript} --specialisation $name
              } catch {
                error make $"switching to the ($name) theme failed"
              }

              reload-applications
            }

            def main [] {
              print $"Usage: tt <dark|light|reload>

                   dark   - Switch to the dark variant
                   light  - Switch to the light variant
                   reload - Reload applications"
            }

            def "main dark" []: nothing -> nothing {
              switch-variant dark
            }

            def "main light" []: nothing -> nothing {
              switch-variant light
            }
          '';
    in
    {
      packages.toggle-theme = toggleTheme;
    };
}
