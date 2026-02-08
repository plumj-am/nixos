#!/usr/bin/env nu
const THEME_CONFIG = "/home/jam/nixos/modules/theme.json"
const THEME_PYWAL = "/home/jam/nixos/modules/theme-pywal-colors.json"
const PYWAL_CONFIG = "/home/jam/.cache/wal/colors.json"
const REBUILD_SCRIPT = "/home/jam/nixos/rebuild.nu"

const HIGH_SAT = 0.75
const MID_SAT = 0.5

def print-notify [message: string]: nothing -> nothing {
   print $"(ansi purple)[Theme Switcher](ansi rst) ($message)"
   try { notify-send "Theme Switcher" $message }
}

def get-current-wallpaper []: nothing -> string {
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

def load-theme-config []: nothing -> nothing {
   try {
      open $THEME_CONFIG
   } catch {
      print-notify "Failed to load default config, falling back to light/gruvbox"
      {mode: light, scheme: gruvbox}
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
   let theme_config = load-theme-config

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

   print-notify $"Rebuilding configuration to apply ($theme) theme."

   do { $REBUILD_SCRIPT }

   print-notify $"Switch to the ($theme) theme completed!"
}

def switch-scheme [scheme: string] {
   print-notify $"Switching to ($scheme) color scheme."

   let theme_config = load-theme-config

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

   print-notify $"Rebuilding configuration to apply ($scheme) scheme..."

   do { $REBUILD_SCRIPT }

   print-notify $"Switch to ($scheme) scheme completed!"
}

def reload-applications []: nothing -> nothing {
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

def main [
   arg: string, # Theme-related action.
]: nothing -> nothing {
   match $arg {
      "dark" | "light" => {
         toggle-theme $arg
         reload-applications
      }
      "pywal" | "gruvbox" => {
         switch-scheme $arg
         reload-applications
      }
      "reload" => {
         do { $REBUILD_SCRIPT }
         reload-applications
      }
      _ => {
         print $"Invalid option: '($arg)'. Use: dark, light, pywal, gruvbox or reload."
      }
   }
}
