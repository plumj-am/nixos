{
  pkgs,
  fenix,
  system,
  nvf,
  bacon-ls,
  ...
}:

{
  imports = [
    nvf.homeManagerModules.default
    ./modules/common.nix
    ./modules/packages.nix
    ./modules/rust.nix
    ./modules/programs
    ./modules/shell
    ./modules/editor
  ];

  _module.args = {
    inherit
      pkgs
      system
      fenix
      nvf
      bacon-ls
      ;
  };

  # generated scripts for cross-platform rebuilds
  home.file."nixos-config/rebuild.nu" = {
    text = ''
      #!/usr/bin/env nu

      def main [] {
          let os = (sys host | get name)
          
          if $os == "Darwin" {
              print "Building Darwin configuration..."
              sudo darwin-rebuild switch --flake ~/nixos-config#darwin
          } else {
              print "Building NixOS configuration..."
              sudo nixos-rebuild switch --flake ~/nixos-config#nixos
          }
      }
    '';
    executable = true;
  };

  home.file."nixos-config/rollback.nu" = {
    text = ''
      #!/usr/bin/env nu

      def main [] {
          let os = (sys host | get name)
          
          if $os == "Darwin" {
              print "Rolling back Darwin configuration..."
              sudo darwin-rebuild switch --rollback --flake ~/nixos-config#darwin
          } else {
              print "Rolling back NixOS configuration..."
              sudo nixos-rebuild switch --rollback --flake ~/nixos-config#nixos
          }
      }
    '';
    executable = true;
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
