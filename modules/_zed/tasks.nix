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
      use_new_terminal = false;
      allow_concurrent_runs = false;
      cwd = "$ZED_WORKTREE_ROOT";
      hide = "on_success";
      reveal = "never";
      shell = fastSh;
    };

  mkPane =
    {
      label,
      command,
      allowMany,
    }:
    {
      inherit label command;
      reveal_target = "center";
      use_new_terminal = true;
      allow_concurrent_runs = allowMany;
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
    allowMany = true;
  })
  (mkPane {
    label = "opencode";
    command = "[ -f .envrc ] && nix develop -c opencode || opencode";
    allowMany = true;
  })
  (mkPane {
    label = "claude-code";
    command = "[ -f .envrc ] && nix develop -c claude || claude";
    allowMany = true;
  })
  (mkPane {
    label = "jjui";
    command = "jjui";
    allowMany = false;
  })
  (mkPane {
    label = "dired";
    command = "lf -command 'set hidden true'";
    allowMany = false;
  })
  (mkPane {
    label = "find_file";
    command = "${tv} files ${tvArgs}";
    allowMany = false;
  })
  (mkPane {
    label = "live_grep";
    command = "raw=$(${tv} text --input '\${ZED_SELECTED_TEXT:-}' ${tvArgs}) && [ -n \"$raw\" ] && result=$(echo \"$raw\" | cut -d: -f1,2) && zed \"$result\"";
    allowMany = false;
  })
]
