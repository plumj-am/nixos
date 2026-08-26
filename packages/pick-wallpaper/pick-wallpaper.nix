{ self, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;

      rebuildScript = getExe self.packages.${pkgs.stdenv.hostPlatform.system}.rebuild;
    in
    {
      packages.pick-wallpaper =
        pkgs.writers.writeNuBin "pick-wallpaper" # nu
          ''
            let wallpaper_dir = $"($env.HOME)/wallpapers"

            try { mkdir $wallpaper_dir }

            let wallpapers = (
              try {
                ls $wallpaper_dir
                | where type == file
                | where name =~ '\.(jpg|png|jpeg|webp|gif)$'
              } catch {
                error make "failed to list wallpapers"
              }
            )

            if ($wallpapers | is-empty) {
              error make "no wallpapers found"
            }

            let selected = $wallpapers
            | get name
            | str join "\n"
            | (^${getExe pkgs.fzf}
              --bind "focus:execute-silent(${getExe pkgs.bash} -c 'nohup ${getExe pkgs.awww} img --transition-type none {} >/dev/null 2>&1 &')"
              --preview-window hidden
              --prompt="Select wallpaper: ")

            if ($selected | is-not-empty) {
              ${getExe pkgs.awww} img --transition-type none $selected | ignore

              print $"Wallpaper set: \(($selected | path basename)\)"

              let theme_config = try {
                open $"($env.HOME)/nixos/modules/theme.json"
              } catch {
                {mode: light, scheme: gruvbox}
              }

              if $theme_config.scheme == matugen {
                print "Regenerating matugen colors..."

                try {
                  ${getExe pkgs.matugen} image $selected --json hex --quiet --source-color-index 0 | save --force $"($env.HOME)/nixos/modules/theme-matugen-colors.json"

                  print "Colors regenerated!"

                  try { ${rebuildScript} } catch { exit 1 }

                  print "Rebuilt system to apply colors."
                } catch {|e|
                  print $"Warning: Failed to regenerate colors: ($e.msg)"
                }
              }
            }
          '';
    };
}
