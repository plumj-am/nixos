{
  config.flake.modules.homeModules.mprocs =
    { pkgs, lib, config, ... }:
    let
      inherit (lib) mkIf;

      package = pkgs.mprocs;
    in
    mkIf config.isDesktop {
      packages = [ package ];

      xdg.config.files."mprocs/mprocs.yaml".text = # yaml
        ''
          hide_keymap_window = true;
          proc_list_width = 18;

          keymap_procs = {
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
          }

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
}
