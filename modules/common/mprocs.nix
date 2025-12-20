{ config, pkgs, lib, ...}: let
  inherit (lib) mkIf;
in {
  environment.systemPackages = lib.optionals config.isDesktop [
    pkgs.mprocs
  ];

  home-manager.sharedModules = [{
    home.file.".config/mprocs/mprocs.yaml" = mkIf config.isDesktop {
      text = /* yaml */ ''
        hide_keymap_window: true
        proc_list_width: 18

        keymap_procs:
          <C-j>:
            c: batch
            cmds:
              - { c: next-proc }
              - { c: focus-term }
          <C-k>:
            c: batch
            cmds:
              - { c: prev-proc }
              - { c: focus-term }

        keymap_term:
          <C-j>:
            c: batch
            cmds:
              - { c: focus-procs }
              - { c: next-proc }
              - { c: focus-term }
          <C-k>:
            c: batch
            cmds:
              - { c: focus-procs }
              - { c: prev-proc }
              - { c: focus-term }
      '';
    };
  }];
}
