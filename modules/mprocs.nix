let
  mprocsBase =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;

      yaml = pkgs.formats.yaml { };

      settings = {
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
    in
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.mprocs;

        xdg.config.files."mprocs/mprocs.yaml".source = yaml.generate "mprocs.yaml" settings;
      };
    };
in
{
  flake.modules.nixos.mprocs = mprocsBase;
  flake.modules.darwin.mprocs = mprocsBase;
}
