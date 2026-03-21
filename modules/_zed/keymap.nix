let
  mkZedKeymap = context: bindings: { inherit context bindings; };

  spawnTask = task_name: [
    "task::Spawn"
    {
      inherit task_name;
      reveal_target = "center";
    }
  ];
in
[
  {
    bindings = {
      ctrl-W = null;
      ctrl-q = null;
      ctrl-F = null;
      ctrl-P = null;
      ctrl-p = null;
      ctrl-H = null;
      ctrl-n = null;
      ctrl-X = null;
      ctrl-k = null;
      "ctrl-=" = "zed::ResetAllZoom";
      alt-h = "workspace::ActivatePaneLeft";
      alt-j = "workspace::ActivatePaneDown";
      alt-k = "workspace::ActivatePaneUp";
      alt-l = "workspace::ActivatePaneRight";
      alt-H = "vim::ResizePaneLeft";
      alt-J = "vim::ResizePaneDown";
      alt-K = "vim::ResizePaneUp";
      alt-L = "vim::ResizePaneRight";
    };
  }
  (mkZedKeymap "Dock && !Terminal" {
    alt-q = "workspace::CloseActiveDock";
    "ctrl-w h" = "workspace::ActivatePaneLeft";
    "ctrl-w l" = "workspace::ActivatePaneRight";
    "ctrl-w k" = "workspace::ActivatePaneUp";
    "ctrl-w j" = "workspace::ActivatePaneDown";
  })
  (mkZedKeymap "Pane" {
    ctrl-w = null;
    alt-q = "pane::CloseCleanItems";
  })
  (mkZedKeymap "Workspace && !Picker" {
    "ctrl-g ctrl-p" = "workspace::Open";
    alt-S = "workspace::ToggleLeftDock";
    alt-s = "project_panel::ToggleFocus";
    alt-T = "workspace::ToggleBottomDock";
    alt-t = "terminal_panel::ToggleFocus";
    alt-D = "workspace::ToggleRightDock";
    alt-d = "debug_panel::ToggleFocus";
    ctrl-t = "task::Spawn";
    ctrl-T = "task::Rerun";

    "ctrl-s" = spawnTask "dired";
    "ctrl-g ctrl-g" = spawnTask "jjui";
    "ctrl-g ctrl-n" = spawnTask "nushell_pane";
    "ctrl-g ctrl-N" = spawnTask "nushell_float";
    "ctrl-g ctrl-o" = spawnTask "opencode";
  })
  (mkZedKeymap "not_editing" {
    "space f" = spawnTask "find_file";
    "space /" = spawnTask "live_grep";
  })
  (mkZedKeymap "VimControl && !menu" {
    ctrl-b = null;
    space = null;
    alt-d = null;
    "space B" = "editor::BlameHover";
    "space b" = "tab_switcher::ToggleAll";
    D = "editor::SelectToEndOfLine";
    ctrl-j = "editor::MoveLineDown";
    ctrl-k = "editor::MoveLineUp";
    enter = "vim::PushSneak";
    shift-enter = "vim::PushSneakBackward";
  })
  (mkZedKeymap "Pane" {
  })
  (mkZedKeymap "BufferSearchBar" {
    "ctrl-w" = [
      "editor::DeleteToPreviousWordStart"
      { ignore_newlines = false; }
    ];
  })
  # (mkZedKeymap "vim_mode == helix_normal || vim_mode == helix_select" {
  #   "space B" = "editor::BlameHover";
  #   "space b" = "tab_switcher::ToggleAll";
  #   D = "editor::SelectToEndOfLine";
  #   ctrl-j = "editor::MoveLineDown";
  #   ctrl-k = "editor::MoveLineUp";
  #   enter = "vim::PushSneak";
  #   shift-enter = "vim::PushSneakBackward";
  # })
  (mkZedKeymap "Terminal" {
    alt-q = "pane::CloseActiveItem";
    alt-H = "pane::SplitLeft";
    alt-L = "pane::SplitRight";
    alt-w = "workspace::ActivateNextPane";
    alt-n = "workspace::NewTerminal";
    alt-u = "terminal::ScrollHalfPageUp";
    alt-d = "terminal::ScrollHalfPageDown";
  })
  (mkZedKeymap "ProjectPanel && not_editing" {
    "/" = null;
    n = "project_panel::NewFile";
    R = "project_panel::Rename";
    "z a" = "project_panel::FoldDirectory";
  })
  (mkZedKeymap "multibuffer" {
    "z z" = "editor::ToggleFoldAll";
  })
]
