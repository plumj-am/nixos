let
  mkScratchpad =
    { pkgs, lib, ... }:
    let
      inherit (lib.meta) getExe;
    in
    {
      name,
      file,
      title,
    }:
    pkgs.writeScriptBin "${name}-scratchpad" /* nu */ ''
      #!${pkgs.nushell}/bin/nu

      let niri_bin = (try { (which niri | get 0.path) } catch { null })

      let scratchpad_class = "${name}-scratchpad"
      let notes_path = ([$env.HOME "notes" "${file}"] | path join)
      let notes_dir = ($notes_path | path dirname)

      if (not ($notes_dir | path exists)) { mkdir $notes_dir }
      if (not ($notes_path | path exists)) { ^${pkgs.uutils-coreutils-noprefix}/bin/touch $notes_path }

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
        ^${getExe pkgs.rio} --app-id $scratchpad_class --title-placeholder "${title}" --working-dir $notes_dir "hx" $notes_path
      } else if $compositor == "niri" and $niri_bin != null {
        let id = ($existing | first | get id?)
        if $id != null { ^$niri_bin msg action close-window --id $id }
      }
    '';
in
{
  flake.modules.nixos.desktop-tools =
    {
      pkgs,
      lib,
      ...
    }:
    let
      mkScratchpad' = mkScratchpad { inherit pkgs lib; };

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
