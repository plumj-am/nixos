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

  # Disable default project_panel opener.
  (mkZedKeymap "Workspace || AgentPanel" {
    ctrl-E = null;
  })

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
      ctrl-alt-h = "vim::ResizePaneLeft";
      ctrl-alt-j = "vim::ResizePaneDown";
      ctrl-alt-k = "vim::ResizePaneUp";
      ctrl-alt-l = "vim::ResizePaneRight";
      alt-H = "pane::SplitLeft";
      alt-J = "pane::SplitDown";
      alt-K = "pane::SplitUp";
      alt-L = "pane::SplitRight";
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
  (mkZedKeymap "TabSwitcher" {
    ctrl-x = "tab_switcher::CloseSelectedItem";
  })
  (mkZedKeymap "BufferSearchBar" {
    "ctrl-w" = [
      "editor::DeleteToPreviousWordStart"
      { ignore_newlines = false; }
    ];
  })
  (mkZedKeymap "Editor && (mode == full)" {
    alt-enter = null; # editor::OpenSelectionsInMultibuffer
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
  (mkZedKeymap "!Terminal" {
    ctrl-C = null; # collab_panel::ToggleFocus
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
