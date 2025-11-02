{ pkgs, config, lib, ... }: let
  inherit (lib) mkIf;

  themeToggleScript = pkgs.writeScriptBin "tt" /* nu */ ''
    #!${pkgs.nushell}/bin/nu

    def print-notify [message: string, progress: int = -1] {
      print $"(ansi purple)[Theme Switcher](ansi rst) ($message)"

      let is_error = ($message | str downcase | str contains "error")
      let urgency = if $is_error { "critical" } else { "normal" }

      let timeout = 5000

      let args = if $progress >= 0 and $progress < 100 {
        ["--hint" $"int:value:($progress)"]
      } else {
        []
      }

      ^${pkgs.libnotify}/bin/notify-send ...$args --urgency=($urgency) --expire-time=($timeout) "Theme Switcher" $"($message)"
    }

    def generate-pywal-colors [wallpaper: string, is_dark: bool] {
      # Clear pywal cache to force regeneration.
      ^${pkgs.coreutils}/bin/rm -rf ~/.cache/wal

      # Build args: start with base args, then append mode-specific ones.
      let base_args = ["-n" "--backend" "wal" "-i" $wallpaper]
      let mode_args = if $is_dark {
        ["--saturate" "0.5"]
      } else {
        ["--saturate" "0.75" "-l"]
      }

      ^${pkgs.pywal}/bin/wal ...($base_args | append $mode_args) err> /dev/null
      ^${pkgs.coreutils}/bin/cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/modules/common/theme/pywal-colors.json"
    }

    def toggle-theme [theme?: string] {
      # Determine current theme and scheme from theme.json file.
      let theme_config = try {
        open $"($env.HOME)/nixos/modules/common/theme/theme.json"
      } catch {
        { mode: "light", scheme: "pywal" }
      }

      let current_theme = $theme_config.mode
      let using_pywal = $theme_config.scheme == "pywal"

      # Use provided theme or error if not provided.
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

      # If using pywal, regenerate colors from current wallpaper.
      if $using_pywal {
        print-notify "Regenerating pywal colors..." 20

        let wallpaper = try {
          ^${pkgs.swww}/bin/swww query | lines | first | parse "{monitor}: image: {path}" | get path.0
        } catch {
          null
        }

        if $wallpaper != null and ($wallpaper | path exists) {
          try {
            generate-pywal-colors $wallpaper ($new_theme == "dark")
            print-notify $"Regenerated ($new_theme) mode pywal colors." 30
          } catch { |e|
            print-notify $"Warning: Failed to regenerate pywal colors: ($e.msg)" 30
          }
        } else {
          print-notify "Warning: Could not detect current wallpaper" 30
        }
      }

      # Update environment and persist to theme.json.
      print-notify "Updating theme configuration..." 40
      $env.THEME_MODE = $new_theme

      let theme_json = $"($env.HOME)/nixos/modules/common/theme/theme.json"
      { mode: $new_theme, scheme: $theme_config.scheme } | to json | save $theme_json --force

      print-notify $"($new_theme | str capitalize) mode activated." 50

      # Rebuild configuration to apply themes.
      print-notify $"Rebuilding configuration to apply ($new_theme) theme." 75

      try {
        ^rebuild --quiet
      } catch { |e|
        print-notify "Error: Rebuild failed, run manually in a terminal."
        exit 1
      }

      print-notify $"Switch to the ($new_theme) theme completed!" 100
    }

    def switch-scheme [scheme: string] {
      # Validate scheme.
      if $scheme not-in ["pywal", "gruvbox"] {
        print-notify $"Invalid scheme: '($scheme)'. Use 'pywal' or 'gruvbox'."
        return
      }

      print-notify $"Switching to ($scheme) color scheme."

      # Get current theme configuration from theme.json file.
      let theme_config = try {
        open $"($env.HOME)/nixos/modules/common/theme/theme.json"
      } catch {
        { mode: "light", scheme: "pywal" }
      }

      # If switching to pywal, generate colors from current wallpaper.
      if $scheme == "pywal" {
        print-notify "Generating pywal colors from current wallpaper..." 25

        let is_dark = $theme_config.mode == "dark"

        let wallpaper = try {
          ^${pkgs.swww}/bin/swww query | lines | first | parse "{monitor}: image: {path}" | get path.0
        } catch {
          null
        }

        if $wallpaper != null and ($wallpaper | path exists) {
          try {
            generate-pywal-colors $wallpaper $is_dark
            print-notify "Generated pywal colors." 50
          } catch { |e|
            print-notify $"Warning: Failed to generate colors: ($e.msg)" 50
          }
        } else {
          print-notify "Warning: Could not detect current wallpaper" 50
        }
      }

      # Update environment and persist to theme.json.
      $env.THEME_SCHEME = $scheme

      let theme_json = $"($env.HOME)/nixos/modules/common/theme/theme.json"
      { mode: $theme_config.mode, scheme: $scheme } | to json | save $theme_json --force

      print $"Updated THEME_SCHEME to ($scheme)"

      # Rebuild configuration to apply new scheme.
      print-notify $"Rebuilding configuration to apply ($scheme) scheme..." 75

      try {
        ^rebuild --quiet
      } catch { |e|
        print-notify "Error: Rebuild failed, run manually in a terminal."
        exit 1
      }

      print-notify $"Switch to ($scheme) scheme completed!" 100
    }

    # Main tt command - handles both light/dark and scheme switching.
    def --wrapped main [
      arg?: string      # Theme mode (dark/light) or color scheme (pywal/gruvbox).
      ...rest: string   # Arbitrary arguments.
    ]: nothing -> nothing {
      if $arg == null {
        print "Usage: tt <dark|light|pywal|gruvbox>"
        return
      }

      match $arg {
        "dark" | "light" => { toggle-theme $arg }
        "pywal" | "gruvbox" => { switch-scheme $arg }
        _ => { print $"Invalid option: '($arg)'. Use: dark, light, pywal, or gruvbox." }
      }
    }
  '';
in {
  environment.systemPackages = mkIf config.isDesktop [
    themeToggleScript
  ];
}
