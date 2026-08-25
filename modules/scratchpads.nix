{
  flake.modules.common.scratchpads =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;

      mkScratchpad =
        name:
        pkgs.writers.writeNuBin "${name}-scratchpad" # nu
          ''
            let niri_bin = try { which niri | get 0.path } catch { null }

            let scratchpad_class = "${name}-scratchpad"
            let notes_path = ([$env.HOME "notes" "${name}.md"] | path join)
            let notes_dir = ($notes_path | path dirname)

            if (not ($notes_dir | path exists)) { mkdir $notes_dir }
            if (not ($notes_path | path exists)) { touch $notes_path }

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
              (^${getExe pkgs.rio}
                --app-id $scratchpad_class
                --title-placeholder "${name}"
                --working-dir $notes_dir
                --command ${getExe pkgs.helix} $notes_path)
            } else if $compositor == "niri" and $niri_bin != null {
              let id = $existing | first | get id?
              if $id != null { ^$niri_bin msg action close-window --id $id }
            }
          '';
    in
    {
      environment.systemPackages = [
        (mkScratchpad "todo")
        (mkScratchpad "random")
      ];
    };
}
