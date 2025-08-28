{
  pkgs,
  lib,
  fenix,
  system,
  nvf,
  bacon-ls,
  fff-nvim,
  ...
}:

{
  imports = [
    nvf.homeManagerModules.default
  ] ++ (lib.collectNix ./modules
    |> lib.remove ./modules/shell/aliases.nix  # data file, not a module
  );

  _module.args = {
    inherit
      pkgs
      system
      fenix
      nvf
      bacon-ls
      fff-nvim
      ;
  };

  # generated scripts for rebuilds
  home.file."nixos-config/rebuild.nu" = {
    text = ''
      #!/usr/bin/env nu

      def main [--remote] {
          let os = (sys host | get name)
          
          let flake = if $remote {
              if $os == "Darwin" {
                  "github:jamesukiyo/nixos#darwin"
              } else {
                  "github:jamesukiyo/nixos#nixos-wsl"
              }
          } else {
              if $os == "Darwin" {
                  "/Users/james/nixos-config#darwin"
              } else {
                  "/home/james/nixos-config#nixos-wsl"
              }
          }
          
          if $os == "Darwin" {
              print $"Building Darwin configuration from ($flake)..."
              sudo darwin-rebuild switch --flake $flake
          } else {
              print $"Building NixOS configuration from ($flake)..."
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
          
          let flake = if $remote {
              if $os == "Darwin" {
                  "github:jamesukiyo/nixos#darwin"
              } else {
                  "github:jamesukiyo/nixos#nixos-wsl"
              }
          } else {
              if $os == "Darwin" {
                  "/Users/james/nixos-config#darwin"
              } else {
                  "/home/james/nixos-config#nixos-wsl"
              }
          }
          
          if $os == "Darwin" {
              print $"Rolling back Darwin configuration from ($flake)..."
              sudo darwin-rebuild switch --rollback --flake $flake
          } else {
              print $"Rolling back NixOS configuration from ($flake)..."
              sudo nixos-rebuild switch --rollback --flake $flake
          }
      }
    '';
    executable = true;
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
