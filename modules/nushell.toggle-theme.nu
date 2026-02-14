#!/usr/bin/env nu
const THEME_CONFIG = "/home/jam/nixos/modules/theme.json"
const THEME_PYWAL = "/home/jam/nixos/modules/theme-pywal-colors.json"
const PYWAL_CONFIG = "/home/jam/.cache/wal/colors.json"
const REBUILD_SCRIPT = "/home/jam/nixos/rebuild.nu"

const HIGH_SAT = 0.75
const MID_SAT = 0.5

def print-notify [message: string] {
   print $"(ansi purple)[Theme Switcher](ansi rst) ($message)"
   try { notify-send "Theme Switcher" $message }
}

def attempt-rebuild [] {
   try { nu $REBUILD_SCRIPT } catch { exit 1 }
}

def get-current-wallpaper [] {
   let wallpaper = swww query
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
   {mode: $mode scheme: $scheme}
   | to json
   | save --force $THEME_CONFIG
}

def update-gsettings [is_dark: bool] {
   let scheme = if $is_dark { "prefer-dark" } else { "default" }
   try { dconf write /org/gnome/desktop/interface/color-scheme $"'($scheme)'" }
}

def get-current-theme [] {
   try {
      open $THEME_CONFIG
   } catch {
      print-notify "Failed to load default config, falling back to light/gruvbox"
      {mode: dark, scheme: gruvbox}
   }
}

def is-current [mode_or_scheme: string] {
   let current = get-current-theme
   if (($current.mode == $mode_or_scheme) or ($current.scheme == $mode_or_scheme)) {
      print-notify "Current theme and scheme already matches the desired settings."
      exit 0
   }

}

def generate-pywal-colors [
   wallpaper: string
   is_dark: bool
]: nothing -> nothing {
   rm --recursive --force ($PYWAL_CONFIG | path dirname)

   let mode_args = if $is_dark {
      [ "--saturate" $MID_SAT ]
   } else {
      [ "--saturate" $HIGH_SAT "-l" ]
   }

   let args = [ "-n" "--backend" wal "-i" $wallpaper ] | append mode_args

   wal ...$args | ignore

   cp $PYWAL_CONFIG $THEME_PYWAL
}

def toggle-theme [theme: string] {
   let theme_config = get-current-theme

   print-notify $"Switching to ($theme) theme."

   if $theme_config.scheme == pywal {
      print-notify "Regenerating pywal colors..."
      let wallpaper = get-current-wallpaper

      if ($wallpaper | is-not-empty) {
         generate-pywal-colors $wallpaper ($theme == dark)
      } else {
         print-notify "Warning: Could not detect current wallpaper"
      }
   }

   print-notify "Updating theme configuration..."

   $env.THEME_MODE = $theme

   save-theme-config $theme $theme_config.scheme

   update-gsettings ($theme == dark)

   print-notify $"Switch to the ($theme) theme completed!"
}

def switch-scheme [scheme: string] {
   print-notify $"Switching to ($scheme) color scheme."

   let theme_config = get-current-theme

   if $scheme == pywal {
      print-notify "Generating pywal colors from current wallpaper..."

      let wallpaper = get-current-wallpaper

      if ($wallpaper | is-not-empty) {
         generate-pywal-colors $wallpaper ($theme_config.mode == dark)
      } else {
         print-notify "Warning: Could not detect current wallpaper"
      }
   }
   $env.THEME_SCHEME = $scheme

   save-theme-config $theme_config.mode $scheme

   print-notify $"Switch to ($scheme) scheme completed!"
}

def reload-applications [] {
   print-notify "Reloading applications..."
   niri msg action do-screen-transition --delay-ms 0 | ignore
   pkill -USR1 kitty | ignore
   pkill -USR2 ghostty | ignore
   pkill -USR1 hx | ignore
   systemctl --user restart mako | ignore
   makoctl reload | ignore
   pkill -SIGTERM brave | ignore
   sleep 1sec
   niri msg action do-screen-transition --delay-ms 500 | ignore
   niri msg action spawn -- brave | ignore
}

def main [] {
   print $"Usage: tt <dark|light|pywal|gruvbox|reload>

      dark    - Switch to dark mode
      light   - Switch to light mode
      pywal   - Use generated pywal colours from wallpaper
      gruvbox - Use the gruvbox theme
      reload  - Reload applications"
}

def "main dark" [--force] {
   if not $force { is-current dark }
   toggle-theme dark
   main reload
}

def "main light" [--force] {
   if not $force { is-current light }
   toggle-theme light
   main reload
}

def "main gruvbox" [--force] {
   if not $force { is-current gruvbox }
   toggle-scheme gruvbox
   main reload
}

def "main pywal" [--force] {
   if not $force { is-current pywal }
   toggle-scheme pywal
   main reload
}

def "main reload" [] {
   attempt-rebuild
   reload-applications
}
