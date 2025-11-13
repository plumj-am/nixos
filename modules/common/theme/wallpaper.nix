{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  set-wallpaper = pkgs.writeTextFile {
    name = "set-wallpaper";
    text = ''
      #!/usr/bin/env nu

      def main [url_or_path: string] {
        if ($url_or_path | str starts-with "http") {
          let wallpaper_dir = $"($env.HOME)/wallpapers"
          mkdir $wallpaper_dir

          # Extract filename from URL
          let filename = ($url_or_path | url parse | get path | path basename)
          let wallpaper_file = $"($wallpaper_dir)/($filename)"

          if ($wallpaper_file | path exists) {
            print $"Wallpaper already exists: ($wallpaper_file)"
            ^${pkgs.swww}/bin/swww img $wallpaper_file o+e>| ignore
            print "Using existing wallpaper"
            return
          }

          print $"Downloading wallpaper to ($wallpaper_file)..."

          try {
            ${pkgs.curl}/bin/curl -L -o $wallpaper_file $url_or_path
            ^${pkgs.swww}/bin/swww img $wallpaper_file o+e>| ignore
            print $"Wallpaper downloaded and set: ($wallpaper_file)"
          } catch {
            print "Failed to download wallpaper"
            exit 1
          }
        } else {
          ^${pkgs.swww}/bin/swww img $url_or_path o+e>| ignore
        }
      }
    '';
    executable = true;
    destination = "/bin/set-wallpaper";
  };

  pick-wallpaper = pkgs.writeTextFile {
    name = "pick-wallpaper";
    text = /* nu */ ''
      #!/usr/bin/env nu

      def main [] {
        let wallpaper_dir = $"($env.HOME)/wallpapers"
        mkdir $wallpaper_dir

        let wallpapers = (ls $wallpaper_dir | where type == file | where name =~ '\.(jpg|png|jpeg|webp|gif)$')

        if ($wallpapers | is-empty) {
          print $"No wallpapers found in ($wallpaper_dir)"
          exit 1
        }

        # Use fzf with chafa for preview
        let selected = (
          $wallpapers
          | get name
          | str join "\n"
          | ^${pkgs.fzf}/bin/fzf --preview $"${pkgs.chafa}/bin/chafa --size 40x20 {}" --preview-window=right:50% --prompt="Select wallpaper: "
        )

        if not ($selected | is-empty) {
          ^${pkgs.swww}/bin/swww img $selected o+e>| ignore
          print $"Wallpaper set: (($selected | path basename))"

          # Regenerate pywal colors if using pywal scheme
          let theme_config = try {
            open $"($env.HOME)/nixos/modules/common/theme/theme.json"
          } catch {
            { mode: "light", scheme: "pywal" }
          }

          let using_pywal = $theme_config.scheme == "pywal"

          if $using_pywal {
            print "Regenerating pywal colors..."

            let is_dark = $theme_config.mode == "dark"

            try {
              # Clear pywal cache to force regeneration
              ^rm -rf ~/.cache/wal

              # Build args: start with base, then append mode-specific ones
              let base_args = ["-n" "--backend" "wal" "-i" $selected]
              let mode_args = if $is_dark {
                ["--saturate" "0.5"]
              } else {
                ["--saturate" "0.75" "-l"]
              }

              ^${pkgs.pywal}/bin/wal ...($base_args | append $mode_args) err> /dev/null
              ^cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/modules/common/theme/pywal-colors.json"
              print "Colors regenerated!"
              try {
                ^rebuild --quiet
              } catch { |e|
                print "Failed to rebuild."
              }
              print "Rebuilt system to apply colors."
            } catch { |e|
              print $"Warning: Failed to regenerate colors: ($e.msg)"
            }
          }
        }
      }
    '';
    executable = true;
    destination = "/bin/pick-wallpaper";
  };

  save-wallpaper = pkgs.writeTextFile {
    name = "save-wallpaper";
    text = ''
      #!/usr/bin/env nu

      def main [url: string] {
        if not ($url | str starts-with "http") {
          print "Error: Please provide a valid URL"
          exit 1
        }

        let wallpaper_dir = $"($env.HOME)/wallpapers"
        mkdir $wallpaper_dir

        # Extract filename from URL
        let filename = ($url | url parse | get path | path basename)
        let wallpaper_file = $"($wallpaper_dir)/($filename)"

        if ($wallpaper_file | path exists) {
          print $"Wallpaper already exists: ($wallpaper_file)"
          return
        }

        print $"Downloading wallpaper to ($wallpaper_file)..."

        try {
          ${pkgs.curl}/bin/curl -L -o $wallpaper_file $url
          print $"Wallpaper saved: ($wallpaper_file)"
        } catch {
          print "Failed to download wallpaper"
          exit 1
        }
      }
    '';
    executable = true;
    destination = "/bin/save-wallpaper";
  };

in mkIf (config.isDesktopNotWsl && !config.isDarwin) {
  environment.systemPackages = [
    pkgs.swww
    pkgs.chafa  # Terminal image viewer for previews.
    set-wallpaper
    pick-wallpaper
    save-wallpaper
  ];

  home-manager.sharedModules = [{
    # Desktop entry for fuzzel.
    xdg.desktopEntries.pick-wallpaper = {
      name     = "Pick Wallpaper";
      icon     = "preferences-desktop-wallpaper";
      exec     = "pick-wallpaper";
      terminal = true;
    };
  }];
}
