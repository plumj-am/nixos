{ pkgs, lib, ... }:
let
  inherit (lib.meta) getExe;

  tv = getExe pkgs.television;
  tvArgs = "--no-remote --no-help-panel --keybindings 'enter=\"confirm_selection\"'";

  fastSh = {
    with_arguments = {
      program = "sh";
      args = [
        "--noediting"
        "--norc"
        "--noprofile"
      ];
    };
  };

  mkFloat =
    { label, command }:
    {
      inherit label;
      command = "kitty --class 'zed_float' -e '${command}'";
      reveal_target = "center";
      use_new_terminal = true;
      allow_concurrent_runs = false;
      cwd = "$ZED_WORKTREE_ROOT";
      hide = "on_success";
      reveal = "never";
      shell = fastSh;
    };

  mkPane =
    { label, command }:
    {
      inherit label command;
      reveal_target = "center";
      use_new_terminal = true;
      allow_concurrent_runs = true;
      cwd = "$ZED_WORKTREE_ROOT";
      hide = "always";
      reveal = "never";
      shell = fastSh;
    };
in
[
  (mkFloat {
    label = "nushell_float";
    command = "nu";
  })
  (mkPane {
    label = "nushell_pane";
    command = "nu";
  })
  (mkPane {
    label = "opencode";
    command = "opencode";
  })
  (mkPane {
    label = "jjui";
    command = "jjui";
  })
  (mkPane {
    label = "find_file";
    command = "${tv} files ${tvArgs}";
  })
  (mkPane {
    label = "live_grep";
    command = "raw=$(${tv} text --input '\${ZED_SELECTED_TEXT:-}' ${tvArgs}) && [ -n \"$raw\" ] && result=$(echo \"$raw\" | cut -d: -f1,2) && zed \"$result\"";
  })
]
