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
      ...$rest)
}

# Rebuild the current or a remote NixOS/nix-darwin host
@example "Rebuild the current host" rebuild
@example "Rebuild a remote host" { rebuild plum }
@example "Rebuild all hosts sequentially" { rebuild all }
def --wrapped main [
   target: string = "" # The host to build (defaults to current)
   --help (-h)         # Show this help message
   ...rest: string     # Extra arguments to pass to nh
]: nothing -> nothing {
   if $help { help main; exit 0 }

   let os = uname | get kernel-name | str downcase
   let config = if $os == darwin {
      {path: /Users/jam/nixos, cmd: $os}
   } else {
      {path: /home/jam/nixos, cmd: os}
   }
   let hostname = sys host | get hostname
   let remote = ($target | is-not-empty) and ($target != $hostname)

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

   let result = if $remote {
      print-notify $"Attempting to start remote build process on ($target)."

      try {
         print-notify $"Removing old configuration files on ($target)."
         ssh -o ConnectTimeout=10 -tt $"jam@($target)" "rm --recursive --force nixos"

         print-notify $"Copying new configuration files to ($target)."
         jj file list | rsync-files --files-from - ./ $"jam@($target):nixos"

         print-notify $"Starting rebuild on ($target)."
         ssh -o ConnectTimeout=10 -qtt $"jam@($target)" ./nixos/rebuild.nu

         true
      } catch {|e|
         print-notify --error $"Something went wrong: ($e.msg)"
         print-notify --error "See above for more information."
         false
      }
   } else {
      print-notify $"Rebuilding (sys host | get hostname)."

      let nh = if (which nh | is-not-empty) {
         [ nh ]
      } else {
         print-notify "Command 'nh' not found, falling back to 'nix run nixpkgs#nh'."
         [ nix run nixpkgs#nh -- ]
      }

      try { sudo ...$nh $config.cmd ...$nh_args; true } catch { false }
   }

   if not $remote {
      if $result {
         print-notify $"Rebuild for ($target) succeeded."
      } else {
         print-notify $"Rebuild for ($target) failed."
      }
   }
}

# Rebuild all hosts sequentially
def "main all" [] {
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

   for h in $HOSTS {
      if ($h == (sys host | get hostname)) {
         main
      } else {
         main $h
      }
   }
}
