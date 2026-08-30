{ self, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;

      rebuildScript = getExe self.packages.${pkgs.stdenv.hostPlatform.system}.rebuild;

      toggleTheme =
        pkgs.writers.writeNuBin "toggle-theme" # nu
          ''
            let NIXOS_CONFIG = $"($env.HOME)/nixos"
            let THEME_CONFIG = $"($NIXOS_CONFIG)/modules/theme.json"
            let THEME_MATUGEN = $"($NIXOS_CONFIG)/modules/theme-matugen-colors.json"

            def get-current-wallpaper []: any -> string {
              let wallpaper = awww query
              | lines
              | first
              | parse "{monitor}: image: {path}"
              | get --optional path.0

              if ($wallpaper | path exists) {
                $wallpaper
              } else {
                ""
              }
            }

            def save-theme-config [mode: string, scheme: string] {
              {mode: $mode, scheme: $scheme}
              | to json
              | try { save --force $THEME_CONFIG } catch {|e|
                print --stderr $"failed to save ($THEME_CONFIG): ($e)"

                exit 1
              }
            }

            def update-gsettings [is_dark: bool]: any -> nothing {
              let scheme = if $is_dark { "prefer-dark" } else { "prefer-light" }

              try {
                dconf write /org/gnome/desktop/interface/color-scheme $"'($scheme)'"
              } catch {|e|
                print --stderr $"failed to save theme via dconf: ($e)"
              }
            }

            def get-current-theme []: any -> record<mode: string, scheme: string> {
              try {
                open $THEME_CONFIG
              } catch {
                print "Failed to load default config, falling back to light/gruvbox"

                {mode: light, scheme: gruvbox}
              }
            }

            def toggle-theme [theme: string]: any -> nothing {
              print $"Switching to ($theme) theme."
              print "Updating theme configuration..."

              let theme_config = get-current-theme

              save-theme-config $theme $theme_config.scheme
              update-gsettings ($theme == dark)

              print $"Switch to the ($theme) theme completed!"
            }

            def switch-scheme [scheme: string]: any -> nothing {
              print $"Switching to ($scheme) color scheme."

              let theme_config = get-current-theme

              if $scheme == matugen {
                print "Generating matugen colors from current wallpaper..."

                let wallpaper = get-current-wallpaper

                if ($wallpaper | is-not-empty) {
                  matugen image $wallpaper --json hex --quiet --source-color-index 0
                  | try {
                    save --force $THEME_MATUGEN
                  } catch {|e|
                    error make $"failed to save generated matugen palette: ($e)"
                  }
                } else {
                  print "Warning: Could not detect current wallpaper"
                }
              }

              save-theme-config $theme_config.mode $scheme
            }

            def restart-apps [apps: list<record<name: string, new: list<string>>>]: nothing -> nothing {
              $apps | par-each {|app|
                pkill -TERM $app.name | ignore

                for _ in 1..30 {
                  if (ps | where name =~ $app.name | is-empty) { break }

                  sleep 100ms
                }

                if (niri msg action spawn -- ...$app.new | complete | get exit_code) != 0 {
                  print --stderr $"Failed to restart ($app.name)"
                }
              }
            }

            def refresh-apps [apps: list<record<name: string, signal: string>>] {
              $apps | par-each {|app|
                if (pkill $"-($app.signal)" $app.name | complete | get exit_code) > 1 {
                  print --stderr $"Failed to reload ($app.name)"
                }
              }
            }

            def reload-applications [mode?: string]: nothing -> nothing {
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
                { refresh-apps $refreshable_apps }
              ] | par-each {|f| do $f}

              print "Application reloading complete."
            }

            def rebuild [] {
              try { sudo ${rebuildScript} } catch {|e| # sudo required
                error make "rebuild failed"
              }
            }

            def main [] {
              print $"Usage: tt <dark|light|matugen|gruvbox|reload>

                   dark    - Switch to dark mode
                   light   - Switch to light mode
                   matugen - Use generated matugen colours from wallpaper
                   gruvbox - Use the gruvbox theme
                   reload  - Reload applications"
            }

            def "main dark" []: nothing -> nothing {
              toggle-theme dark
              rebuild
              reload-applications "dark"
            }

            def "main light" []: nothing -> nothing {
              toggle-theme light
              rebuild
              reload-applications "light"
            }

            def "main gruvbox" []: nothing -> nothing {
              switch-scheme gruvbox
              rebuild
              reload-applications
            }

            def "main matugen" []: nothing -> nothing {
              switch-scheme matugen
              rebuild
              reload-applications
            }
          '';
    in
    {
      packages.toggle-theme = toggleTheme;
      packages.tt = toggleTheme;
    };
}
