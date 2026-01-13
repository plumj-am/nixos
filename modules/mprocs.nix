{
  flake.modules.hjem.mprocs =
    {
      pkgs,
      lib,
      isDesktop,
      ...
    }:
    let
      inherit (lib.modules) mkIf;

      package = pkgs.mprocs;
    in
    mkIf isDesktop {
      packages = [ package ];

      xdg.config.files."mprocs/mprocs.yaml".text = # yaml
        ''
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
}
