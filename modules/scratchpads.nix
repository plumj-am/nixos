{ lib, ... }:
let
  inherit (lib) getExe';

  mkScratchpad =
    { pkgs, ... }:
    {
      name,
      file,
      title,
    }:
    let
      hx = getExe' pkgs.helix "hx";
    in
    pkgs.writeScriptBin "${name}-scratchpad" /* nu */ ''
      #!${pkgs.nushell}/bin/nu

      let niri_bin = (try { (which niri | get 0.path) } catch { null })

      let scratchpad_class = "${name}-scratchpad"
      let notes_path = ([$env.HOME "notes" "${file}"] | path join)
      let notes_dir = ($notes_path | path dirname)

      if (not ($notes_dir | path exists)) { mkdir $notes_dir }
      if (not ($notes_path | path exists)) { ^${pkgs.coreutils}/bin/touch $notes_path }

      let compositor = if $niri_bin != null {
          "niri"
        } else {
          "unknown"
        }

      let windows = if $compositor == "niri" {
          try { ^$niri_bin msg --json windows | from json } catch { [] }
      } else {
        []
      }

      let existing = if $compositor == "niri" {
          $windows | where app_id? == $scratchpad_class
      } else {
        []
      }

      if ($existing | is-empty) {
        ^${pkgs.kitty}/bin/kitty --detach --class $scratchpad_class --title "${title}" --override remember_window_size=no --override initial_window_width=80c --override initial_window_height=24c --directory $notes_dir ${hx} $notes_path
      } else if $compositor == "niri" and $niri_bin != null {
        let id = ($existing | first | get id?)
        if $id != null { ^$niri_bin msg action close-window --id $id }
      }
    '';

in
{
  config.flake.modules.nixos.scratchpads =
    { pkgs, ... }:
    let
      mkScratchpad' = mkScratchpad { inherit pkgs; };

      todoScratchpad = mkScratchpad' {
        name = "todo";
        file = "todo.md";
        title = "Todo";
      };
      randomScratchpad = mkScratchpad' {
        name = "random";
        file = "random.md";
        title = "Random";
      };
    in
    {
      environment.systemPackages = [
        todoScratchpad
        randomScratchpad
      ];
    };
}
