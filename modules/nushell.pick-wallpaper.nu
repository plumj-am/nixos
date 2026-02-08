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
      --preview
      "chafa --size 40x20 {}"
      --preview-window=right:50%
      --prompt="Select wallpaper: ")

if ($selected | is-not-empty) {
   swww img $selected | ignore # nu-lint-ignore: redundant_ignore

   print $"Wallpaper set: \(($selected | path basename)\)"

   let theme_config = try {
      open $"($env.HOME)/nixos/modules/theme.json"
   } catch {
      {mode: light, scheme: gruvbox}
   }
   if $theme_config.scheme == pywal {
      print "Regenerating pywal colors..."

      try {
         rm --recursive --force ~/.cache/wal

         let base_args = ["-n" "--backend" wal "-i" $selected]

         let mode_args = if $theme_config.mode == dark {
            ["--saturate" "0.5"]
         } else {
            ["--saturate" "0.75" "-l"]
         }

         wal ...($base_args | append $mode_args) | ignore # nu-lint-ignore: redundant_ignore

         cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/modules/theme-pywal-colors.json"

         print "Colors regenerated!"

         try { /home/jam/nixos/rebuild.nu } catch { exit 1 }
         print "Rebuilt system to apply colors."
      } catch {|e| print $"Warning: Failed to regenerate colors: ($e.msg)" }
   }
}
