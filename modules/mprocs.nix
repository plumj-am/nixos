{
  flake.modules.common.mprocs =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule = {
        packages = singleton pkgs.mprocs;

        xdg.config.files."mprocs/mprocs.yaml" = {
          generator = pkgs.writers.writeYAML "mprocs.yaml";
          value = {
            hide_keymap_window = true;
            proc_list_width = 18;

            keymap_procs = {
              "<C-j>" = {
                c = "batch";
                cmds = [
                  { c = "next-proc"; }
                  { c = "focus-term"; }
                ];
              };
              "<C-k>" = {
                c = "batch";
                cmds = [
                  { c = "prev-proc"; }
                  { c = "focus-term"; }
                ];
              };
            };

            keymap_term = {
              "<C-j>" = {
                c = "batch";
                cmds = [
                  { c = "focus-procs"; }
                  { c = "next-proc"; }
                  { c = "focus-term"; }
                ];
              };
              "<C-k>" = {
                c = "batch";
                cmds = [
                  { c = "focus-procs"; }
                  { c = "prev-proc"; }
                  { c = "focus-term"; }
                ];
              };
            };
          };
        };
      };
    };
}
