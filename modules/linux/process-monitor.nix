{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  btopPopupConfig = pkgs.writeText "btop-popup.conf" /* conf */ ''
    tty_mode = True
    force_tty = True
    shown_boxes = "proc"
    proc_left = False
    proc_tree = False
    proc_gradient = False
    proc_colors = False
    proc_per_core = False
    proc_mem_bytes = False
    proc_cpu_graphs = False
    proc_mem_graphs = False
    mem_graphs = False
    show_detailed = False
    show_cpu_freq = False
    show_uptime = False
    show_disks = False
    show_io_stat = False
    show_swap = False
  '';

  process-monitor = pkgs.writeScriptBin "process-monitor" /* nu */ ''
    #!${pkgs.nushell}/bin/nu

    let niri_bin = (try { (which niri | get 0.path) } catch { null })
    let class_name = "btop-popup"

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
        $windows | where app_id? == $class_name
      } else {
        []
      }

    if ($existing | is-empty) {
      ^${pkgs.kitty}/bin/kitty --detach --class $class_name --title "Process Monitor" --override remember_window_size=no --override initial_window_width=44c --override initial_window_height=16c --override window_padding_width=${toString (config.theme.padding.small)} ${pkgs.btop}/bin/btop --config ${btopPopupConfig}
    } else if $compositor == "niri" and $niri_bin != null {
      let id = ($existing | first | get id?)
      if $id != null { ^$niri_bin msg action close-window --id $id }
    }
  '';
in mkIf config.isDesktopNotWsl {
  environment.systemPackages = [
    process-monitor
  ];
}
