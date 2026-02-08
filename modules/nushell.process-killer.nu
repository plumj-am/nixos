#!/usr/bin/env nu
def launcher-select [prompt: string]: list<string> -> string {
   str join "\n"
   | tofi --prompt-text $prompt
}

def notify []: string -> nothing {
   try { notify-send "Process Killer" $in }
   if $in =~ Error { exit 1 } # nu-lint-ignore: exit_only_in_main
}

let all_procs = ps

let procs = $all_procs
| where name != null
| reverse
| select pid name
| each {|p| $"($p.name) [PID: ($p.pid)]" }

if ($procs | is-empty) { "Error: No processes found" | notify }

let pid = $procs
| launcher-select "[pkill]"
| parse "{name} [PID: {pid}]"
| get --optional pid.0
| into int

if ($pid | is-empty) { "Error: Could not extract PID" | notify }

let process_name = $all_procs
| where pid == $pid
| get --optional name.0

if ($process_name | is-empty) { "Error: Process not found" | notify }

let confirm = [Yes No] | launcher-select $"Kill ($process_name) \(PID: ($pid)\)? "
if $confirm == Yes {
   try {
      kill $pid
      $"Killed ($process_name) \(PID: ($pid)\)" | notify
   } catch {
      $"Could not kill ($process_name) \(PID: ($pid)\)" | notify
   }
}
