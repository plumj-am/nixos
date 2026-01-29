{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.trivial) fromHexString;
  inherit (lib.types) attrs;
  inherit (lib.attrsets) listToAttrs elemAt;
  inherit (lib.lists) genList;
  inherit (builtins)
    fromJSON
    readFile
    substring
    pathExists
    ;

  # Shared theme configuration logic
  mkThemeConfig =
    { pkgs }:
    let
      themeConfig = fromJSON (readFile ./theme.json);
      isDark = themeConfig.mode == "dark";
      colorScheme = themeConfig.scheme;

      pywalCache = ./theme-pywal-colors.json;

      parsePywalColors =
        json:
        let
          colors = fromJSON json;
          stripHash = s: substring 1 6 s;
          colorNames = [
            "base00"
            "base01"
            "base02"
            "base03"
            "base04"
            "base05"
            "base06"
            "base07"
            "base08"
            "base09"
            "base0A"
            "base0B"
            "base0C"
            "base0D"
            "base0E"
            "base0F"
          ];
        in
        listToAttrs (
          genList (n: {
            name = elemAt colorNames n;
            value = stripHash (elemAt colors.colors.colors n);
          }) 16
        );

      pywalColorsRaw = if pathExists pywalCache then readFile pywalCache else null;

      pywalColors =
        if pywalColorsRaw != null then parsePywalColors pywalColorsRaw else gruvboxColors.dark;

      gruvboxColors = {
        dark = {
          base00 = "1d2021";
          base01 = "3c3836";
          base02 = "504945";
          base03 = "665c54";
          base04 = "bdae93";
          base05 = "d5c4a1";
          base06 = "ebdbb2";
          base07 = "fbf1c7";
          base08 = "fb4934";
          base09 = "fe8019";
          base0A = "fabd2f";
          base0B = "b8bb26";
          base0C = "8ec07c";
          base0D = "83a598";
          base0E = "d3869b";
          base0F = "d65d0e";
        };
        light = {
          base00 = "f9f5d7";
          base01 = "ebdbb2";
          base02 = "d5c4a1";
          base03 = "bdae93";
          base04 = "665c54";
          base05 = "504945";
          base06 = "3c3836";
          base07 = "282828";
          base08 = "9d0006";
          base09 = "af3a03";
          base0A = "b57614";
          base0B = "79740e";
          base0C = "427b58";
          base0D = "076678";
          base0E = "8f3f71";
          base0F = "d65d0e";
        };
      };

      colors =
        if colorScheme == "pywal" then
          pywalColors
        else
          (if isDark then gruvboxColors.dark else gruvboxColors.light);

      variant = if isDark then "dark" else "light";

      hexToRgb =
        hex:
        let
          r = fromHexString (substring 0 2 hex);
          g = fromHexString (substring 2 2 hex);
          b = fromHexString (substring 4 2 hex);
        in
        [
          r
          g
          b
        ];

      designSystem = {
        radius = {
          off = 0;
          small = 2;
          normal = 4;
          big = 6;
          verybig = 8;
        };

        border = {
          small = 2;
          normal = 4;
          big = 6;
        };

        margin = {
          small = 4;
          normal = 8;
          big = 32;
        };

        padding = {
          small = 4;
          normal = 8;
        };

        opacity = {
          opaque = 1.00;
          veryhigh = 0.99;
          high = 0.97;
          medium = 0.94;
          low = 0.90;
          verylow = 0.80;
        };

        duration = {
          s = {
            short = 0.5;
            normal = 1.0;
            long = 1.5;
          };
          ms = {
            short = 150;
            normal = 200;
            long = 300;
          };
        };
      };

      themes = {
        alacritty.dark = "gruvbox_material_hard_dark";
        alacritty.light = "gruvbox_material_hard_light";

        ghostty.dark = "Gruvbox Dark Hard";
        ghostty.light = "Gruvbox Light Hard";

        rio.dark = "gruvbox-dark-hard";
        rio.light = "gruvbox-light-hard";

        zellij.dark = "gruvbox-dark";
        zellij.light = "gruvbox-light";

        starship.dark = "dark_theme";
        starship.light = "light_theme";

        vivid.dark = "gruvbox-dark";
        vivid.light = "gruvbox-light";

        nushell.dark = "dark-theme";
        nushell.light = "light-theme";

        helix.dark = "gruvbox_dark_hard";
        helix.light = "gruvbox_light_hard";

        gtk.dark = {
          name = "Gruvbox-Dark";
          package = pkgs.gruvbox-gtk-theme;
        };
        gtk.light = {
          name = "Adwaita";
          package = pkgs.gnome-themes-extra;
        };

        qt.dark = {
          name = "adwaita-dark";
          platformTheme = "adwaita";
        };
        qt.light = {
          name = "adwaita";
          platformTheme = "adwaita";
        };

        icons.dark = {
          name = "Gruvbox-Plus-Dark";
          package = pkgs.gruvbox-plus-icons;
        };
        icons.light = {
          name = "Papirus-Light";
          package = pkgs.papirus-icon-theme;
        };
      };

      getTheme = program: if isDark then themes.${program}.dark else themes.${program}.light;
    in
    {
      inherit
        isDark
        colorScheme
        variant
        colors
        designSystem
        themes
        getTheme
        hexToRgb
        ;
    };

in
{
  flake.modules.darwin.theme =
    { pkgs, ... }:
    let
      theme = mkThemeConfig { inherit pkgs; };
    in
    {
      options.theme = mkOption {
        type = attrs;
        default = { };
        description = "Global theme configuration";
      };

      config = {
        theme = theme.designSystem // {
          inherit (theme)
            themes
            isDark
            colorScheme
            variant
            colors
            ;

          withHash = mapAttrs (_name: value: "#${value}") theme.colors;
          with0x = mapAttrs (_name: value: "0x${value}") theme.colors;
          withRgb = mapAttrs (_name: value: theme.hexToRgb value) theme.colors;

          icons = theme.getTheme "icons";
          alacritty = theme.getTheme "alacritty";
          ghostty = theme.getTheme "ghostty";
          rio = theme.getTheme "rio";
          zellij = theme.getTheme "zellij";
          starship = theme.getTheme "starship";
          vivid = theme.getTheme "vivid";
          nushell = theme.getTheme "nushell";
          helix = theme.getTheme "helix";
          gtk = theme.getTheme "gtk";
          qt = theme.getTheme "qt";

          font = {
            size.tiny = 10;
            size.small = 12;
            size.term = 12;
            size.normal = 16;
            size.big = 20;

            mono.name = "Maple Mono NF";
            mono.family = "Maple Mono";
            mono.package = pkgs.maple-mono.NF;

            sans.name = "Lexend";
            sans.family = "Lexend";
            sans.package = pkgs.lexend;
          };
        };
      };
    };

  flake.modules.nixos.theme =
    { pkgs, ... }:
    let
      theme = mkThemeConfig { inherit pkgs; };
    in
    {
      options.theme = mkOption {
        type = attrs;
        default = { };
        description = "Global theme configuration";
      };

      config = {
        theme = theme.designSystem // {
          inherit (theme)
            themes
            isDark
            colorScheme
            variant
            colors
            ;

          withHash = mapAttrs (_name: value: "#${value}") theme.colors;
          with0x = mapAttrs (_name: value: "0x${value}") theme.colors;
          withRgb = mapAttrs (_name: value: theme.hexToRgb value) theme.colors;

          icons = theme.getTheme "icons";
          alacritty = theme.getTheme "alacritty";
          ghostty = theme.getTheme "ghostty";
          rio = theme.getTheme "rio";
          zellij = theme.getTheme "zellij";
          starship = theme.getTheme "starship";
          vivid = theme.getTheme "vivid";
          nushell = theme.getTheme "nushell";
          helix = theme.getTheme "helix";
          gtk = theme.getTheme "gtk";
          qt = theme.getTheme "qt";

          font = {
            size.tiny = 10;
            size.small = 12;
            size.term = 12;
            size.normal = 16;
            size.big = 20;

            mono.name = "Maple Mono NF";
            mono.family = "Maple Mono";
            mono.package = pkgs.maple-mono.NF;

            sans.name = "Lexend";
            sans.family = "Lexend";
            sans.package = pkgs.lexend;
          };
        };
      };
    };

  flake.modules.nixos.theme-extra-fonts =
    { config, pkgs, ... }:
    {
      console = {
        earlySetup = true;
        font = "Lat2-Terminus16";
        packages = [ pkgs.terminus_font ];
      };

      fonts.fontconfig.enable = true;

      fonts.packages = [
        config.theme.font.mono.package
        config.theme.font.sans.package
        pkgs.noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-lgc-plus
        pkgs.noto-fonts-color-emoji
      ];
    };

  flake.modules.nixos.theme-extra-scripts =
    { config, pkgs, ... }:
    let
      inherit (builtins) map;
      inherit (config.myLib) mkDesktopEntry;

      pickWallpaper = pkgs.writeScriptBin "pick-wallpaper" /* nu */ ''
        #!/usr/bin/env nu

        def main [] {
          let wallpaper_dir = $"($env.HOME)/wallpapers"
          mkdir $wallpaper_dir

          let wallpapers = (ls $wallpaper_dir | where type == file | where name =~ '\.(jpg|png|jpeg|webp|gif)$')

          if ($wallpapers | is-empty) {
            print $"No wallpapers found in ($wallpaper_dir)"
            exit 1
          }

          let selected = (
            $wallpapers
            | get name
            | str join "\n"
            | ${pkgs.fzf}/bin/fzf --preview $"${pkgs.chafa}/bin/chafa --size 40x20 {}" --preview-window=right:50% --prompt="Select wallpaper: "
          )

          if not ($selected | is-empty) {
            ${pkgs.swww}/bin/swww img $selected o+e>| ignore
            print $"Wallpaper set: (($selected | path basename))"

            let theme_config = try {
              open $"($env.HOME)/nixos/modules/theme.json"
            } catch {
              { mode: "light", scheme: "pywal" }
            }

            let using_pywal = $theme_config.scheme == "pywal"

            if $using_pywal {
              print "Regenerating pywal colors..."

              let is_dark = $theme_config.mode == "dark"

              try {
                rm -rf ~/.cache/wal

                let base_args = ["-n" "--backend" "wal" "-i" $selected]
                let mode_args = if $is_dark {
                  ["--saturate" "0.5"]
                } else {
                  ["--saturate" "0.75" "-l"]
                }

                ${pkgs.pywal}/bin/wal ...($base_args | append $mode_args) err> /dev/null
                cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/modules/theme-pywal-colors.json"
                print "Colors regenerated!"
                try { rebuild --quiet } catch { exit 1 }
                print "Rebuilt system to apply colors."
              } catch { |e|
                print $"Warning: Failed to regenerate colors: ($e.msg)"
              }
            }
          }
        }
      '';

      # Theme toggle script
      themeToggleScript = pkgs.writeScriptBin "tt" /* nu */ ''
        #!${pkgs.nushell}/bin/nu

        def print-notify [message: string, progress: int = -1] {
          print $"(ansi purple)[Theme Switcher](ansi rst) ($message)"

          ${pkgs.libnotify}/bin/notify-send "Theme Switcher" $"($message)"
        }

        def generate-pywal-colors [wallpaper: string, is_dark: bool] {
          ${pkgs.coreutils}/bin/rm -rf ~/.cache/wal

          let base_args = ["-n" "--backend" "wal" "-i" $wallpaper]
          let mode_args = if $is_dark {
            ["--saturate" "0.5"]
          } else {
            ["--saturate" "0.75" "-l"]
          }

          ${pkgs.pywal}/bin/wal ...($base_args | append $mode_args) err> /dev/null
          ${pkgs.coreutils}/bin/cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/modules/theme-pywal-colors.json"
        }

        def reload-applications [] {
          print-notify "Reloading applications to apply themes..."

          try {
            niri msg action do-screen-transition --delay-ms 0 | complete
            pkill waybar -USR2 | complete # Better to do it here rather than relying on `reload_style_on_change` setting.
            pkill -USR1 kitty | complete
            pkill -USR2 ghostty | complete
            pkill -USR1 hx | complete
            systemctl --user restart mako | complete
            pkill -SIGTERM brave | complete
            sleep 1sec
            niri msg action do-screen-transition --delay-ms 500 | complete
            niri msg action spawn -- brave | complete
          } catch {|e|
             print $e.msg
          }
        }

        def toggle-theme [theme?: string] {
          let theme_config = try {
            open $"($env.HOME)/nixos/modules/theme.json"
          } catch {
            { mode: "light", scheme: "pywal" }
          }

          let current_theme = $theme_config.mode
          let using_pywal = $theme_config.scheme == "pywal"

          let new_theme = if $theme != null {
            if $theme in ["light", "dark"] {
              $theme
            } else {
              print-notify $"Invalid theme: '($theme)'. Use 'light' or 'dark'."
              return
            }
          } else {
            print-notify "Theme argument required. Use 'light' or 'dark'."
            return
          }

          print-notify $"Switching to ($new_theme) theme."

          if $using_pywal {
            print-notify "Regenerating pywal colors..."

            let wallpaper = try {
              ${pkgs.swww}/bin/swww query | lines | first | parse "{monitor}: image: {path}" | get path.0
            } catch {
              null
            }

            if $wallpaper != null and ($wallpaper | path exists) {
              try {
                generate-pywal-colors $wallpaper ($new_theme == "dark")
                print-notify $"Regenerated ($new_theme) mode pywal colors."
              } catch { |e|
                print-notify $"Warning: Failed to regenerate pywal colors: ($e.msg)"
              }
            } else {
              print-notify "Warning: Could not detect current wallpaper"
            }
          }

          print-notify "Updating theme configuration..."
          $env.THEME_MODE = $new_theme

          let theme_json = $"($env.HOME)/nixos/modules/theme.json"
          { mode: $new_theme, scheme: $theme_config.scheme } | to json | save $theme_json --force

          print-notify $"($new_theme | str capitalize) mode activated."

          print-notify $"Rebuilding configuration to apply ($new_theme) theme."

          try { rebuild --quiet } catch { exit 1 }

          print-notify $"Switch to the ($new_theme) theme completed!"

          reload-applications
        }

        def switch-scheme [scheme: string] {
          if $scheme not-in ["pywal", "gruvbox"] {
            print-notify $"Invalid scheme: '($scheme)'. Use 'pywal' or 'gruvbox'."
            return
          }

          print-notify $"Switching to ($scheme) color scheme."

          let theme_config = try {
            open $"($env.HOME)/nixos/modules/theme.json"
          } catch {
            { mode: "light", scheme: "pywal" }
          }

          if $scheme == "pywal" {
            print-notify "Generating pywal colors from current wallpaper..."

            let is_dark = $theme_config.mode == "dark"

            let wallpaper = try {
              ${pkgs.swww}/bin/swww query | lines | first | parse "{monitor}: image: {path}" | get path.0
            } catch {
              null
            }

            if $wallpaper != null and ($wallpaper | path exists) {
              try {
                generate-pywal-colors $wallpaper $is_dark
                print-notify "Generated pywal colors."
              } catch { |e|
                print-notify $"Warning: Failed to generate colors: ($e.msg)"
              }
            } else {
              print-notify "Warning: Could not detect current wallpaper"
            }
          }

          $env.THEME_SCHEME = $scheme

          let theme_json = $"($env.HOME)/nixos/modules/theme.json"
          { mode: $theme_config.mode, scheme: $scheme } | to json | save $theme_json --force

          print $"Updated THEME_SCHEME to ($scheme)"

          print-notify $"Rebuilding configuration to apply ($scheme) scheme..."

          try { rebuild --quiet } catch { exit 1 }

          print-notify $"Switch to ($scheme) scheme completed!"

          reload-applications
        }

        def --wrapped main [
          arg?: string
          ...rest: string
        ]: nothing -> nothing {
          if $arg == null {
            print "Usage: tt <dark|light|pywal|gruvbox|reload>"
            return
          }

          match $arg {
            "dark" | "light" => { toggle-theme $arg }
            "pywal" | "gruvbox" => { switch-scheme $arg }
            "reload" => {
              reload-applications
              try { rebuild --quiet } catch { exit 1 }
            }
            _ => { print $"Invalid option: '($arg)'. Use: dark, light, pywal, gruvbox or reload." }
          }
        }
      '';
    in
    {
      environment.systemPackages = [
        pkgs.swww
        themeToggleScript
        pickWallpaper
      ]
      ++ (map (mkDesktopEntry { inherit pkgs; }) [
        {
          name = "Dark-Mode";
          exec = "tt dark";
        }
        {
          name = "Light-Mode";
          exec = "tt light";
        }
        {
          name = "Pywal-Mode";
          exec = "tt pywal";
        }
        {
          name = "Gruvbox-Mode";
          exec = "tt gruvbox";
        }
        {
          name = "Reload-Applications";
          exec = "tt reload";
        }
        {
          name = "Pick-Wallpaper";
          exec = "pick-wallpaper";
          terminal = true;
        }
      ]);
    };
}
