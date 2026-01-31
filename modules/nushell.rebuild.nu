#!/usr/bin/env nu
# nu-lint-ignore: print_and_return_data
def print-notify [
   quiet: bool
   message: string
]: nothing -> nothing {
   if not $quiet {
      print $"(ansi purple)[Rebuilder](ansi rst) ($message)"
      try { notify-send Rebuilder $message }
   }
}

# nu-lint-ignore: max_function_body_length
def --wrapped main [
   host: string = ""    # The host to build.
   --remote             # Deploy to remote host using --target-host.
   --rollback           # Rollback.
   --quiet(-q)          # Run without output (for theme toggling).
   ...arguments: string # Extra arguments to pass to rebuild commands.
]: nothing -> nothing {
   let os = sys host | get long_os_version | split words | get --optional 0
   let config_path = if $os == Darwin { "/Users/jam/nixos" } else { "/home/jam/nixos" }
   let hostname = sys host | get hostname

   let nixos_configs = nix flake show --json | from json | get nixosConfigurations | columns
   let darwin_configs = nix flake show --json | from json | get darwinConfigurations | columns

   let host = if ($host | is-not-empty) {
      if $host != ($hostname) and not $remote {
         print-notify $quiet $"Error: Building local configuration for hostname that does not match the local machine."
         exit 1
      }
      $host
   } else if $remote {
      print-notify $quiet "Error: Hostname not specified for remote deployment."
      exit 1
   } else { $hostname }

   # Build locally (always).
   let os = (uname | get kernel-name)
   # nh os/darwin switch [flake_path] --hostname [host] -- [nix_args]
   let base_args = [
      switch
      $config_path
      --hostname $host
      --accept-flake-config
   ] | append $arguments

   # Add target-host for remote deployments.
   let final_args = if $remote {
      $base_args | append [
         "--target-host"
         $"root@($host)"
      ]
   } else { $base_args }

   let command = if $rollback {
      rollback
   } else {
      if $os == Darwin { "darwin" } else { "os" }
   }

   let final_args = if $rollback {
      [$host] | append $arguments
   } else {
      $final_args
   }

   let action = if $remote {
      $"Deploying to: ($host)"
   } else {
      "Building locally:"
   }

   let platform = if $os == Darwin { "Darwin" } else { "NixOS" }

   print-notify $quiet $"($action) ($platform). Configuration for: ($host)."

   if $remote {
      try {
         nh $command ...$final_args
      } catch {
         print-notify $quiet "Rebuild failed. Try again in a terminal."
         exit 1
      }
   } else {
      try {
         sudo NH_BYPASS_ROOT_CHECK=true NH_NO_CHECKS=true nh $command ...$final_args # nu-lint-ignore: wrap_external_with_complete
      } catch {
         print-notify $quiet "Rebuild failed. Try again in a terminal."
         exit 1
      }
   }
   if $rollback {
      print-notify $quiet $"Rollback for ($host) succeeded."
   } else {
      print-notify $quiet $"Rebuild for ($host) succeeded."
   }
}
