#!/usr/bin/env nu

# nu-lint-ignore: print_and_return_data
def print-notify [
   message: string
]: nothing -> nothing {
   print $"(ansi purple)[Rebuilder](ansi rst) ($message)\r"
   if (which notify-send | is-not-empty) {
     notify-send Rebuilder $message
   }
}

def --wrapped rsync-files [
   ...rest: string
]: string -> string {
      (rsync
      --archive
      --compress
      --delete --recursive --force
      --delete-excluded
      --delete-missing-args
      --human-readable
      --delay-updates
      ...$rest)
}

def remote-build [
   target: string
   --quiet
]: nothing -> record {
   print-notify $"Attempting to start remote build process on ($target)."

   if not $quiet { print-notify $"Removing old configuration files on ($target)." }
   (ssh -qtt $"jam@($target)" "rm --recursive --force nixos" | complete)

   if not $quiet { print-notify $"Copying new configuration files to ($target)." }
   (jj file list | rsync-files --files-from - ./ $"jam@($target):nixos" | complete)

   (ssh -qtt $"jam@($target)" ./nixos/rebuild.nu | complete)
}

def build [
   cmd: string
   ...args: string
]: nothing -> record {
   let nh = if (which nh | is-not-empty) {
      [ nh ]
   } else {
      print-notify "Command 'nh' not found, falling back to 'nix run nixpkgs#nh'."
      [ nix run nixpkgs#nh -- ]
   }

   print-notify $"Rebuilding (sys host | get hostname)."

   sudo ...$nh $cmd ...$args | complete
}

# nu-lint-ignore: max_function_body_length
def start-progress-bar []: nothing -> int { # nu-lint-ignore: print_and_return_data
   job spawn {
      sleep 100ms # Give time to spawn before starting animation.

      const WIDTH = 10

      mut s = 1.0
      mut m = 0
      mut pos = 0
      mut dir = 1

      while $env.REBUILD_IN_PROGRESS {
         $s += 0.1

         $pos += $dir
         if $pos >= $WIDTH or $pos <= 0 { $dir *= -1 }

         let l = ('' | fill --width $pos --character ' ')
         let r = ('' | fill --width ($WIDTH - $pos) --character ' ')

         if $s == 60.0 { $m += 1 }

         let s = $s | into int

         let msg = $"(ansi p)($l)█($r)(ansi rst) Elapsed: ($s)s\r"
         print --no-newline $msg
         job send 0
         sleep 100ms
      }
   }
}

def --wrapped main [ # nu-lint-ignore: max_function_body_length
   --remote: string = "" # Build a remote host
   --all                 # Attempt to rebuild all hosts
   ...rest: string       # Extra arguments to pass to nh
]: nothing -> nothing {
   let os = uname | get kernel-name | str downcase
   let config = if $os == darwin {
      {path: /Users/jam/nixos, cmd: $os}
   } else {
      {path: /home/jam/nixos, cmd: os}
   }
   let hostname = sys host | get hostname
   let remote = $remote | str trim | str downcase
   let is_remote = $remote | is-not-empty

   const HOSTS = [
      blackwell
      date
      kiwi
      lime
      pear
      plum
      sloe
      yuzu
   ]

   let target = if $is_remote {
      if $remote == $hostname {
         print-notify "Error: Attempting to build the current systems configuration as a remote system."
         exit 1
      }
      $remote
   } else { $hostname }

   let nix_args = [
      --
      --fallback
   ]

   let nh_args = [
      switch
      $config.path
      --accept-flake-config
      --bypass-root-check
      ...$nix_args
      ...$rest
   ]

   if $all {
      print-notify $"Rebuilding all hosts in parallel: ($HOSTS)."
      print-notify "Results will be collected and shown upon completion."
      print-notify "This will take some time."

      $env.REBUILD_IN_PROGRESS = true

      start-progress-bar

      let results = $HOSTS | par-each --keep-order {|h|
         let remote = $h != $hostname
         if $is_remote {
            let result = remote-build --quiet $h
            {host: $h, success: ($result.exit_code == 0), stderr: $result.stderr}
         } else {
            let result = build $config.cmd ...$nh_args
            {host: $h, success: ($result.exit_code == 0), stderr: $result.stderr}
         }
      }

      $env.REBUILD_IN_PROGRESS = false

      print-notify "All builds complete."
      for r in $results {
         if $r.success {
            print-notify $"✓ ($r.host)"
         } else {
            print-notify $"✗ ($r.host) failed"
            if $r.stderr != null {
               print-notify $" stderr: ($r.stderr)"
            }
         }
      }
      return
   }

   $env.REBUILD_IN_PROGRESS = true

   start-progress-bar

   let result = if $is_remote {
      remote-build $target
   } else {
      build $config.cmd ...$nh_args
   }

   $env.REBUILD_IN_PROGRESS = false

   match $result.exit_code {
      0 => { print-notify $"Rebuild for ($target) succeeded." }
      _ => {
         print-notify $"Rebuild for ($target) failed."
         print-notify $"Error: ($result)"
      }
   }
}
