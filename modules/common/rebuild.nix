{ ... }: {
  home-manager.sharedModules = [{
    # generated scripts for rebuilds
    home.file."nixos-config/rebuild.nu" = {
    text = ''
      #!/usr/bin/env nu

      def main [--remote] {
          let os = (sys host | get name)
          let hostname = (hostname | str trim)

          let config_path = if $os == "Darwin" { "/Users/james/nixos-config" } else { "/home/james/nixos-config" }

          let flake = if $remote {
              $"github:jamesukiyo/nixos#($hostname)"
          } else {
              $"($config_path)#($hostname)"
          }

          if $os == "Darwin" {
              print $"Building Darwin configuration for ($hostname) from ($flake)..."
              sudo darwin-rebuild switch --flake $flake
          } else {
              print $"Building NixOS configuration for ($hostname) from ($flake)..."
              sudo nixos-rebuild switch --flake $flake
          }
      }
    '';
    executable = true;
  };

    home.file."nixos-config/rollback.nu" = {
    text = ''
      #!/usr/bin/env nu

      def main [--remote] {
          let os = (sys host | get name)
          let hostname = (hostname | str trim)

          let config_path = if $os == "Darwin" { "/Users/james/nixos-config" } else { "/home/james/nixos-config" }

          let flake = if $remote {
              $"github:jamesukiyo/nixos#($hostname)"
          } else {
              $"($config_path)#($hostname)"
          }

          if $os == "Darwin" {
              print $"Rolling back Darwin configuration for ($hostname) from ($flake)..."
              sudo darwin-rebuild switch --rollback --flake $flake
          } else {
              print $"Rolling back NixOS configuration for ($hostname) from ($flake)..."
              sudo nixos-rebuild switch --rollback --flake $flake
          }
      }
    '';
    executable = true;
    };
  }];
}