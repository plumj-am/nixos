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
          let theme_file = $"($env.HOME)/nixos/modules/common/theme.nix"
          let using_pywal = try {
            let content = open $theme_file
            $content | str contains 'color_scheme = "pywal";'
          } catch {
            false
          }

          if $using_pywal {
            print "Regenerating pywal colors..."

            # Determine if dark mode
            let is_dark = try {
              let content = open $theme_file
              $content | str contains "is_dark = true;"
            } catch {
              false
            }

            try {
              # Clear pywal cache to force regeneration
              ^rm -rf ~/.cache/wal

              let wal_args = if $is_dark {
                ["-n" "--saturate" "0.7" "-i" $selected]
              } else {
                ["-n" "--saturate" "0.6" "-l" "-i" $selected]
              }
              ^${pkgs.pywal}/bin/wal --backend wal ...$wal_args err> /dev/null
              ^cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/pywal-colors.json"
              print "Colors regenerated!"
              try {
                nu -l -c "~/rebuild.nu --quiet"
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

in mkIf config.isDesktopNotWsl {
  environment.systemPackages = [
    pkgs.swww
    pkgs.chafa  # Terminal image viewer for previews.
    set-wallpaper
    pick-wallpaper
    save-wallpaper
  ];

  home-manager.sharedModules = [{
    # Auto-start swww daemon and set wallpaper based on theme.
    wayland.windowManager.hyprland.settings.exec-once = [
      "swww-daemon"
    ];

    # Desktop entry for fuzzel.
    xdg.desktopEntries.pick-wallpaper = {
      name     = "Pick Wallpaper";
      exec     = "pick-wallpaper";
      terminal = true;
    };
  }];
}
