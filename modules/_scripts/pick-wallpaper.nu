#!/usr/bin/env nu
let wallpaper_dir = $"($env.HOME)/wallpapers"
try { mkdir $wallpaper_dir }

let wallpapers = (
   try {
      ls $wallpaper_dir
      | where type == file
      | where name =~ '\.(jpg|png|jpeg|webp|gif)$'
   } catch {
      print --stderr "Failed to list wallpapers"
      exit 1
   }
)
if ($wallpapers | is-empty) {
   print --stderr $"No wallpapers found in ($wallpaper_dir)"
   exit 1
}
let selected = $wallpapers
   | get name
   | str join "\n"
   | (fzf
      --bind "focus:execute-silent(bash -c 'nohup awww img --transition-type none {} >/dev/null 2>&1 &')"
      --preview-window hidden
      --prompt="Select wallpaper: ")

if ($selected | is-not-empty) {
   awww img --transition-type none $selected | ignore
   print $"Wallpaper set: \(($selected | path basename)\)"

   let theme_config = try {
      open $"($env.HOME)/nixos/modules/theme.json"
   } catch {
      {mode: light, scheme: gruvbox}
   }
   if $theme_config.scheme == matugen {
      print "Regenerating matugen colors..."

      try {
         matugen image $selected --json hex --quiet --source-color-index 0 | save --force $"($env.HOME)/nixos/modules/theme-matugen-colors.json"

         print "Colors regenerated!"

         try { /home/jam/nixos/rebuild.nu } catch { exit 1 }
         print "Rebuilt system to apply colors."
      } catch {|e| print $"Warning: Failed to regenerate colors: ($e.msg)" }
   }
}
