#!/usr/bin/env nu
let NIXOS_CONFIG = $"($env.HOME)/nixos"
let THEME_CONFIG = $"($NIXOS_CONFIG)/modules/theme.json"
let THEME_MATUGEN = $"($NIXOS_CONFIG)/modules/theme-matugen-colors.json"
let REBUILD_SCRIPT = $"($NIXOS_CONFIG)/rebuild.nu"

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
      {name: "kitty", signal: "USR1"}
      {name: "ghostty", signal: "USR2"}
      {name: "hx", signal: "USR1"}
      {name: "opencode", signal: "USR2"}
   ]

   let helium_mode = if $mode == "dark" { ["helium" "--force-dark-mode"] } else { ["helium" "--force-light-mode"] }

   let restartable_apps = [
      {name: "helium", new: $helium_mode}
   ]

   [
      {
         if (qs --no-duplicate -p /home/jam/nixos/modules/quickshell/shell ipc call shell reload | complete | get exit_code) != 0 {
            print --stderr "Failed to reload quickshell"
         }
      }
      { refresh-apps $refreshable_apps }
      { restart-apps $restartable_apps }
   ] | par-each {|f| do $f}

   print "Application reloading complete."
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

   try { nu $REBUILD_SCRIPT } catch {|e|
      print --stderr "rebuild failed"

      exit 1
   }

   reload-applications "dark"
}

def "main light" [
   --force # Run the theme toggle even if current theme matches desired theme
]: nothing -> nothing {
   if not $force { is-current light }

   toggle-theme light

   try { nu $REBUILD_SCRIPT } catch {|e|
      print --stderr "rebuild failed"

      exit 1
   }

   reload-applications "light"
}

def "main gruvbox" [
   --force # Run the theme toggle even if current theme matches desired theme
]: nothing -> nothing {
   if not $force { is-current gruvbox }

   switch-scheme gruvbox

   try { nu $REBUILD_SCRIPT } catch {|e|
      print --stderr "rebuild failed"

      exit 1
   }

   reload-applications
}

def "main matugen" [
   --force # Run the theme toggle even if current theme matches desired theme
]: nothing -> nothing {
   if not $force { is-current matugen }

   switch-scheme matugen

   try { nu $REBUILD_SCRIPT } catch {|e|
      print --stderr "rebuild failed"

      exit 1
   }

   reload-applications
}
