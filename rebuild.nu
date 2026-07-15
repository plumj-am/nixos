#!/usr/bin/env nu
def --wrapped rsync-files [...rest: string]: any -> string {
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

@example "Rebuild the current host" rebuild
@example "Rebuild a remote host" { rebuild --remote plum }
@example "Rebuild all hosts sequentially" { rebuild all }
def --wrapped main [
   --remote: string # The host to build (defaults to current)
   --help (-h)      # Show this help message
   ...rest: string  # Extra arguments to pass to nh
]: nothing -> nothing {
   if $help {
      help main

      exit 0
   }

   let os: string = uname | get kernel-name | str lowercase

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
      "auto-allocate-uids flakes nix-command pipe-operators cgroups"
   ]

   let nh_args = [
      switch
      $config.path
      --accept-flake-config
      --bypass-root-check
      --builders
      ""
      ...$nix_args
      ...$rest
   ]

   let result = if $is_remote {
      print $"Attempting to start remote build process on ($remote)."

      try {
         print $"Removing old configuration files on ($remote)."

         ssh -o ConnectTimeout=10 -o RemoteCommand=none -tt $"jam@($remote)" "rm --recursive --force nixos"

         cd $config.path

         print $"Copying new configuration files to ($remote)."

         jj file list | rsync-files --files-from - ./ $"jam@($remote):nixos"

         print $"Starting rebuild on ($remote)."

         ssh -o ConnectTimeout=10 -o RemoteCommand=none -qtt $"jam@($remote)" ./nixos/rebuild.nu

         true
      } catch {|e|
         print --stderr $"Something went wrong: ($e.msg)"

         print --stderr "See above for more information."

         false
      }
   } else {
      print $"Rebuilding ($hostname)."

      let nh = if (which nh | is-not-empty) {
         [nh]
      } else {
         print "Command 'nh' not found, falling back to 'nix run nixpkgs#nh'."

         [
            nix
            --extra-experimental-features
            "auto-allocate-uids nix-command flakes pipe-operators cgroups"
            run
            nixpkgs#nh
            --
         ]
      }

      try {
         sudo ...$nh $config.cmd ...$nh_args

         true
      } catch { false }
   }

   if not $is_remote {
      if $result {
         print $"Rebuild for ($remote | default --empty $hostname) succeeded."
      } else {
         print $"Rebuild for ($remote | default --empty $hostname) failed."
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
      if $h == (sys host | get hostname) {
         main
      } else {
         main --remote $h
      }
   }
}
