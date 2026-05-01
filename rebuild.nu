#!/usr/bin/env nu

def print-notify [message: string, --error (-e)] {
   if $error {
      print $"(ansi red)[Rebuilder](ansi rst) ($message)"
   } else {
      print $"(ansi purple)[Rebuilder](ansi rst) ($message)"
   }

   try { notify-send Rebuilder $message }
}

def --wrapped rsync-files [...rest: string] {
      (rsync
      --archive
      --compress
      --delete --recursive --force
      --delete-excluded
      --delete-missing-args
      --human-readable
      --delay-updates
      --rsh "ssh -o RemoteCommand=none"
      ...$rest)
}

# Rebuild the current or a remote NixOS/nix-darwin host
@example "Rebuild the current host" rebuild
@example "Rebuild a remote host" { rebuild --remote plum }
@example "Rebuild all hosts sequentially" { rebuild all }
def --wrapped main [
   --remote: string # The host to build (defaults to current)
   --help (-h)      # Show this help message
   ...rest          # Extra arguments to pass to nh
]: nothing -> nothing {
   if $help { help main; exit 0 }

   let os = uname | get kernel-name | str downcase
   let config = if $os == darwin {
      {path: /Users/jam/nixos, cmd: $os}
   } else {
      {path: /home/jam/nixos, cmd: os}
   }
   let hostname = sys host | get hostname
   let is_remote = ($remote | is-not-empty) and ($remote != $hostname)

   let nix_args = [
      --
      --fallback
      --option
      experimental-features
      "flakes nix-command pipe-operators cgroups"
   ]

   let nh_args = [
      switch
      $config.path
      --accept-flake-config
      --bypass-root-check
      --builders ""
      ...$nix_args
      ...$rest
   ]

   let result = if $is_remote {
      print-notify $"Attempting to start remote build process on ($remote)."

      try {
         print-notify $"Removing old configuration files on ($remote)."
         ssh -o ConnectTimeout=10 -o RemoteCommand=none -tt $"jam@($remote)" "rm --recursive --force nixos"

         print-notify $"Copying new configuration files to ($remote)."
         jj file list | rsync-files --files-from - ./ $"jam@($remote):nixos"

         print-notify $"Starting rebuild on ($remote)."
         ssh -o ConnectTimeout=10 -o RemoteCommand=none -qtt $"jam@($remote)" ./nixos/rebuild.nu

         true
      } catch {|e|
         print-notify --error $"Something went wrong: ($e.msg)"
         print-notify --error "See above for more information."
         false
      }
   } else {
      print-notify $"Rebuilding ($hostname)."

      let nh = if (which nh | is-not-empty) {
         [ nh ]
      } else {
         print-notify "Command 'nh' not found, falling back to 'nix run nixpkgs#nh'."
         [ nix --extra-experimental-features "nix-command flakes pipe-operators cgroups" run nixpkgs#nh -- ]
      }

      try { sudo ...$nh $config.cmd ...$nh_args; true } catch { false }
   }

   if not $is_remote {
      if $result {
         print-notify $"Rebuild for ($remote | default --empty $hostname) succeeded."
      } else {
         print-notify $"Rebuild for ($remote | default --empty $hostname) failed."
      }
   }
}

# Rebuild all hosts sequentially
def "main all" [] {
   const HOSTS = [
      # blackwell
      date
      kiwi
      lime
      pear
      plum
      sloe
      yuzu
   ]

   for h in $HOSTS {
      if ($h == (sys host | get hostname)) {
         main
      } else {
         main --remote $h
      }
   }
}
