{
  flake.modules.nixos.process-management =
    { pkgs, config, ... }:
    let
      processKiller = pkgs.writeScriptBin "process-killer" /* nu */ ''
        #!${pkgs.nushell}/bin/nu
        def get_processes [] {
          let nu_pids = ps | where name == "nu" | get pid
          let filter_pids = if ($nu_pids | is-empty) { [] } else { $nu_pids }

          ps
          | where pid not-in $filter_pids
          | where cpu != null and mem != null and name != null
          | sort-by cpu
          | reverse
          | select pid cpu mem name
          | each { |p|
              try {
                $"($p.name) (CPU: ($p.cpu | math round -p 1)%, MEM: ($p.mem | math round -p 1)%) [PID: ($p.pid)]"
              } catch {
                $"($p.name) [PID: ($p.pid)]"
              }
            }
          | where ($it | str length) > 0
        }

        def extract_pid [choice: string] {
          $choice | parse "{name} [PID: {pid}]" | get pid.0? | into int
        }

        def get_process_name [pid: int] {
          ps | where pid == $pid | get name.0?
        }

        def fuzzel_select [items: list<string>, prompt: string] {
          $items | str join "\n" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt $prompt
        }

        def notify [title: string, message: string] {
          ^${pkgs.libnotify}/bin/notify-send $title $message
        }

        def kill_process [pid: int] {
          try {
            kill $pid
            true
          } catch {
            false
          }
        }

        def main [] {
          let processes = get_processes

          if ($processes | is-empty) {
            notify "Error" "No processes found"
            return
          }

          let choice = fuzzel_select $processes "Kill process: "

          if ($choice | is-empty) {
            return
          }

          let pid = extract_pid $choice

          if ($pid | is-empty) {
            notify "Error" "Could not extract PID"
            return
          }

          let process_name = get_process_name $pid

          if ($process_name | is-empty) {
            notify "Error" "Process not found"
            return
          }

          let confirm = fuzzel_select ["Yes" "No"] ($"Kill ($process_name) \(PID: ($pid | into string)\)? ")

          if $confirm == "Yes" {
            if (kill_process $pid) {
              notify "Process Killed" ($"Killed ($process_name) \(PID: ($pid | into string)\)")
            } else {
              notify "Failed" ($"Could not kill ($process_name) \(PID: ($pid | into string)\)")
            }
          }
        }
      '';

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

      processMonitor = pkgs.writeScriptBin "process-monitor" /* nu */ ''
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
          ^${pkgs.kitty}/bin/kitty --detach --class $class_name --title "Process Monitor" --override remember_window_size=no --override initial_window_width=44c --override initial_window_height=16c --override window_padding_width=${toString config.theme.padding.small} ${pkgs.btop}/bin/btop --config ${processMonitorConfig}
        } else if $compositor == "niri" and $niri_bin != null {
          let id = ($existing | first | get id?)
          if $id != null { ^$niri_bin msg action close-window --id $id }
        }
      '';

    in
    {
      environment.systemPackages = [
        processKiller
        processMonitor
      ];
    };
}
