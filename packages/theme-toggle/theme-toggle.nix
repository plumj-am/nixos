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

            def switch-variant [mode: string]: nothing -> nothing {
              let name = $mode
              print $"Switching to the ($name) theme."

              try {
                sudo env $"NH_FLAKE=($NIXOS_CONFIG)" ${rebuildScript} --specialisation $name
              } catch {
                error make $"switching to the ($name) theme failed"
              }

              update-gsettings
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
