{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (lib.meta) getExe;

      rebuild = getExe self.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      packages.theme =
        pkgs.writers.writeNuBin "theme" # nu
          ''
            const THEME_STATE = "/etc/theme.json"
            const DCONF_PATH = "/org/gnome/desktop/interface/color-scheme"

            def update-gsettings []: nothing -> nothing {
              let scheme = match (open $THEME_STATE | default {mode: dark}).mode {
                "light" => "prefer-light"
                _       => "prefer-dark"
              }

              try {
                ^${getExe pkgs.dconf} write $DCONF_PATH $"'($scheme)'"
              } catch {|e|
                print --stderr $"failed to save theme via dconf: ($e)"
              }
            }

            def switch-variant [mode: string]: nothing -> nothing {
              print $"Switching to the ($mode) theme."

              try {
                ^${rebuild} deploy --specialisation $mode
              } catch {|e|
                error make $"Switching to the ($mode) theme failed: ($e)"
              }

              update-gsettings
            }

            def main [mode: string] {
              let valid_modes = ["light" "dark"]
              if $mode not-in $valid_modes {
                error make $"Invalid mode: '($mode)'. Valid modes: ($valid_modes | str join ", ")"
              }

              switch-variant $mode
            }
          '';
    };
}
