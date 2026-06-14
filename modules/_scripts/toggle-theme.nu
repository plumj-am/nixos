#!/usr/bin/env nu
const THEME_CONFIG = "/home/jam/nixos/modules/theme.json"
const THEME_MATUGEN = "/home/jam/nixos/modules/theme-matugen-colors.json"
const REBUILD_SCRIPT = "/home/jam/nixos/rebuild.nu"

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
   let scheme = if $is_dark { "prefer-dark" } else { "default" }

   try {
      dconf write /org/gnome/desktop/interface/color-scheme $"'($scheme)'"
   } catch {|e| print --stderr $"failed to save theme via dconf: ($e)" }
}

def get-current-theme []: any -> nothing {
   try {
      open $THEME_CONFIG
   } catch {
      print "Failed to load default config, falling back to light/gruvbox"

      {mode: dark, scheme: gruvbox}
   }
}

def is-current [mode_or_scheme: string] {
   let current = get-current-theme

   if ($current.mode == $mode_or_scheme) or ($current.scheme == $mode_or_scheme) {
      print "Current theme and scheme already matches the desired settings."

      exit 0
   }
}

def toggle-theme [theme: string]: any -> nothing {
   print $"Switching to ($theme) theme."

   print "Updating theme configuration..."

   let theme_config = get-current-theme

   $env.THEME_MODE = $theme

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
            print --stderr $"failed to save generated matugen palette: ($e)"

            exit 1
         }
      } else {
         print "Warning: Could not detect current wallpaper"
      }
   }

   $env.THEME_SCHEME = $scheme

   save-theme-config $theme_config.mode $scheme
}

def det-failure []: int -> int {
   if $in not-in [0 1] { 1 } else { 0 }
}

def reload-applications []: any -> string {
   print "Reloading applications..."

   mut failure_count = 0

   $failure_count += (niri msg action do-screen-transition --delay-ms 0 | complete | get exit_code) | det-failure

   $failure_count += (
        qs --no-duplicate -p /home/jam/nixos/modules/quickshell/shell ipc call shell reload
        | complete
        | get exit_code
    ) | det-failure

   $failure_count += (pkill -USR1 kitty | complete | get exit_code) | det-failure

   $failure_count += (pkill -USR2 ghostty | complete | get exit_code) | det-failure

   $failure_count += (pkill -USR1 hx | complete | get exit_code) | det-failure

   $failure_count += (pkill -USR2 opencode | complete | get exit_code) | det-failure

   # $failure_count += (pkill -SIGTERM brave | complete | get exit_code) | det-failure
   # sleep 1sec
   # $failure_count += (niri msg action do-screen-transition --delay-ms 500 | complete | get exit_code) | det-failure
   # $failure_count += (niri msg action spawn -- brave | complete | get exit_code) | det-failure

   if $failure_count > 0 {
      print $"($failure_count) reloads failed in 'reload-applications'. Exiting."
   } else {
      print "Applications reloaded successfully."
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

def "main dark" [
   --force # Run the theme toggle even if current theme matches desired theme
]: nothing -> nothing {
   if not $force { is-current dark }

   toggle-theme dark

   main reload
}

def "main light" [
   --force # Run the theme toggle even if current theme matches desired theme
]: nothing -> nothing {
   if not $force { is-current light }

   toggle-theme light

   main reload
}

def "main gruvbox" [
   --force # Run the theme toggle even if current theme matches desired theme
]: nothing -> nothing {
   if not $force { is-current gruvbox }

   switch-scheme gruvbox

   main reload
}

def "main matugen" [
   --force # Run the theme toggle even if current theme matches desired theme
]: nothing -> nothing {
   if not $force { is-current matugen }

   switch-scheme matugen

   main reload
}

def "main reload" []: nothing -> nothing {
   try { nu $REBUILD_SCRIPT } catch { exit 1 }

   reload-applications

   print "Theme switch complete!"
}
