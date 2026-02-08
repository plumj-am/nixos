let
  processManagementBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib) readFile;
      inherit (lib.lists) singleton;

      processKiller = pkgs.writeScriptBin "process-killer" (readFile ./nushell.process-killer.nu);

      processMonitorConfig = pkgs.writeText "btop-popup.conf" /* conf */ ''
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

      processMonitor =
        pkgs.writeScriptBin "process-monitor" # nu
          ''
            #!${pkgs.nushell}/bin/nu
            const CLASS_NAME = "btop-popup"

            let existing = try {
              niri msg --json windows
              | from json
              | where app_id? == $CLASS_NAME
            } catch { return }


            if ($existing | is-not-empty) {
              niri msg action close-window --id $existing
            } else {
              (kitty
                --detach
                --class $CLASS_NAME
                --title "Process Monitor"
                --override remember_window_size=no
                --override initial_window_width=44c
                --override initial_window_height=16c
                --override window_padding_width=${toString config.theme.padding.small}
                btop
                --config ${processMonitorConfig})
            }
          '';

    in
    {
      hjem.extraModules = singleton {
        packages = [
          processKiller
          processMonitor
        ];
      };
    };
in
{
  flake.modules.nixos.process-management = processManagementBase;
}
