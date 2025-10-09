{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf getExe';

  hx = getExe' pkgs.helix "hx";

  mkScratchpad = { name, file, title }: pkgs.writeScriptBin "${name}-scratchpad" /* nu */ ''
    #!${pkgs.nushell}/bin/nu

    let hyprctl = "${pkgs.hyprland}/bin/hyprctl"
    let niri_bin = (try { (which niri | get 0.path) } catch { null })

    let scratchpad_class = "${name}-scratchpad"
    let notes_path = ([$env.HOME "notes" "${file}"] | path join)
    let notes_dir = ($notes_path | path dirname)

    if (not ($notes_dir | path exists)) { mkdir $notes_dir }
    if (not ($notes_path | path exists)) { ^${pkgs.coreutils}/bin/touch $notes_path }

    let compositor = if (try { $env.NIRI_SOCKET } catch { null }) != null {
        "niri"
      } else if (try { $env.HYPRLAND_INSTANCE_SIGNATURE } catch { null }) != null {
        "hyprland"
      } else if $niri_bin != null {
        "niri"
      } else {
        "unknown"
      }

    let windows = if $compositor == "niri" and $niri_bin != null {
        try { ^$niri_bin msg --json windows | from json } catch { [] }
      } else if $compositor == "hyprland" {
        try { ^$hyprctl clients -j | from json } catch { [] }
      } else {
        []
      }

    let existing = if $compositor == "niri" {
        $windows | where app_id? == $scratchpad_class
      } else if $compositor == "hyprland" {
        $windows | where class? == $scratchpad_class
      } else {
        []
      }

    if ($existing | is-empty) {
      ^${pkgs.kitty}/bin/kitty --detach --class $scratchpad_class --title "${title}" --override remember_window_size=no --override initial_window_width=80c --override initial_window_height=24c --directory $notes_dir ${hx} $notes_path
    } else if $compositor == "niri" and $niri_bin != null {
      let id = ($existing | first | get id?)
      if $id != null { ^$niri_bin msg action close-window --id $id }
    } else if $compositor == "hyprland" {
      let address = ($existing | first | get address?)
      if $address != null { ^$hyprctl dispatch closewindow $"address:($address)" }
    }
  '';

  todoScratchpad   = mkScratchpad { name = "todo";   file = "todo.md";   title = "Todo"; };
  randomScratchpad = mkScratchpad { name = "random"; file = "random.md"; title = "Random"; };

in mkIf config.isDesktopNotWsl {
  environment.systemPackages = [
    todoScratchpad
    randomScratchpad
  ];
}
