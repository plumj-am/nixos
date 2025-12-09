{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  process-killer = pkgs.writeScriptBin "process-killer" /* nu */ ''
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
in mkIf config.isDesktopNotWsl {
  environment.systemPackages = [
    process-killer
  ];
}
