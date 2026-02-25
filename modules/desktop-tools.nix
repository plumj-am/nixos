let
  mkScratchpad =
    { pkgs, ... }:
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
        ^${pkgs.kitty}/bin/kitty --detach --class $scratchpad_class --title "${title}" --override remember_window_size=no --override initial_window_width=80c --override initial_window_height=24c --directory $notes_dir "hx" $notes_path
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
      config,
      ...
    }:
    let
      inherit (config.myLib) mkDesktopEntry;
      inherit (lib) readFile;

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

      powerMenu = pkgs.writeScriptBin "power-menu" (readFile ./nushell.power-menu.nu);
    in
    {
      environment.systemPackages = [
        pkgs.thunar
        pkgs.tumbler

        pkgs.hyprpicker

        (mkDesktopEntry {
          name = "Colour-Picker";
          exec = "hyprpicker --format=hex --autocopy";
        })

        todoScratchpad
        randomScratchpad

        powerMenu
      ];
    };
}
