{ config, lib, ... }:
let
	inherit (lib) enabled;
in
{
  programs.zellij = enabled {
    enableBashIntegration = true;

    attachExistingSession = true;
    exitShellOnExit       = false;

    settings = {
      theme = config.theme.zellij;

      default_shell     = "nu";
      scrollback_editor = "hx";

      default_layout        = "james";
      session_serialization = true;
      auto_layout           = true;
      mirror_session        = false;
      on_force_close        = "detach";

      pane_frames       = false;
      simplified_ui     = true;
      show_startup_tips = false;

      mouse_mode         = false;
      scroll_buffer_size = 5000;

      copy_on_select = false;
      copy_clipboard = "system";

      default_mode = "locked";

      pane_viewport_serialization   = true;
      scrollback_lines_to_serialize = 5000;

      env.EDITOR = "hx";
			env.SHELL  = "nu";

      simplified_ui_default_plugin     = "compact-bar";
      ui.pane_frames.hide_session_name = false;
			ui.pane_frames.rounded_corners   = false;

      keybinds = {
        _props.clear-defaults = true;

        # Locked mode
        locked._children = [
          {
            bind._args              = [ "Ctrl g" ];
						bind.SwitchToMode._args = [ "normal" ];
          }
        ];

        # Normal mode
        normal._children = [
          {
						bind._args              = [ "Esc" ];
						bind.SwitchToMode._args = [ "locked" ];
          }
          {
						bind._args              = [ "Ctrl p" ];
						bind.SwitchToMode._args = [ "pane" ];
          }
          {
						bind._args              = [ "Ctrl t" ];
						bind.SwitchToMode._args = [ "tab" ];
          }
          {
						bind._args              = [ "Ctrl r" ];
						bind.SwitchToMode._args = [ "resize" ];
          }
          {
						bind._args              = [ "Ctrl s" ];
						bind.SwitchToMode._args = [ "scroll" ];
          }
          {
						bind._args              = [ "Ctrl o" ];
						bind.SwitchToMode._args = [ "session" ];
          }
          {
						bind._args     = [ "Ctrl h" ];
						bind.MoveFocus = [ "Left" ];
          }
          {
						bind._args     = [ "Ctrl l" ];
						bind.MoveFocus = [ "Right" ];
          }
          {
						bind._args     = [ "Ctrl j" ];
						bind.MoveFocus = [ "Down" ];
          }
          {
						bind._args     = [ "Ctrl k" ];
						bind.MoveFocus = [ "Up" ];
          }
          {
						bind._args      = [ "Ctrl x" ];
						bind.CloseFocus = { };
          }
          {
						bind._args           = [ "H" ];
						bind.GoToPreviousTab = { };
          }
          {
						bind._args       = [ "L" ];
						bind.GoToNextTab = { };
          }
          {
            bind._args     = [ "Ctrl f" ];
            bind._children = [
							{
								LaunchOrFocusPlugin = {
									_args    = [ "https://github.com/karimould/zellij-forgot/releases/latest/download/zellij_forgot.wasm" ];
									floating = true;
								};
							}
						];
          }
          {
            bind._args     = [ "Ctrl j" ];
            bind._children = [
              {
                Run = {
                  _args         = [ "lazyjj" ];
                  close_on_exit = true;
                  floating      = true;
                  x             = "5%";
                  y             = "5%";
                  width         = "90%";
                  height        = "90%";
                };
              }
            ];
          }
          {
            bind._args     = [ "Ctrl n" ];
            bind._children = [
              {
                Run = {
                  _args         = [ "nu" ];
                  close_on_exit = true;
                  floating      = true;
                  x             = "5%";
                  y             = "5%";
                  width         = "90%";
                  height        = "90%";
                };
              }
            ];
          }
          {
						bind._args         = [ "q" ];
						bind.GoToTab._args = [ 1 ];
          }
          {
						bind._args         = [ "w" ];
						bind.GoToTab._args = [ 2 ];
          }
          {
						bind._args         = [ "e" ];
						bind.GoToTab._args = [ 3 ];
          }
          {
            bind._args         = [ "r" ];
						bind.GoToTab._args = [ 4 ];
          }
          {
            bind._args         = [ "t" ];
						bind.GoToTab._args = [ 5 ];
          }
          {
            bind._args         = [ "y" ];
						bind.GoToTab._args = [ 6 ];
          }
          {
						bind._args         = [ "u" ];
						bind.GoToTab._args = [ 7 ];
          }
          {
						bind._args         = [ "i" ];
						bind.GoToTab._args = [ 8 ];
          }
          {
						bind._args         = [ "o" ];
						bind.GoToTab._args = [ 9 ];
          }
        ];

        # Pane mode
        pane._children = [
          {
						bind._args              = [ "Esc" ];
						bind.SwitchToMode._args = [ "locked" ];
          }
          {
            bind._args              = [ "Enter" ];
						bind.SwitchToMode._args = [ "normal" ];
          }
          {
						bind._args     = [ "h" ];
						bind.MoveFocus = [ "Left" ];
          }
          {
						bind._args     = [ "l" ];
						bind.MoveFocus = [ "Right" ];
          }
          {
						bind._args     = [ "j" ];
						bind.MoveFocus = [ "Down" ];
          }
          {
						bind._args     = [ "k" ];
						bind.MoveFocus = [ "Up" ];
          }
          {
						bind._args   = [ "n" ];
						bind.NewPane = { };
          }
          {
						bind._args         = [ "d" ];
						bind.NewPane._args = [ "Down" ];
          }
          {
						bind._args         = [ "r" ];
						bind.NewPane._args = [ "Right" ];
          }
          {
						bind._args      = [ "x" ];
						bind.CloseFocus = { };
          }
          {
						bind._args                 = [ "f" ];
						bind.ToggleFocusFullscreen = { };
          }
          {
						bind._args            = [ "z" ];
						bind.TogglePaneFrames = { };
          }
          {
						bind._args               = [ "w" ];
						bind.ToggleFloatingPanes = { };
          }
        ];

        # Tab mode
        tab._children = [
          {
						bind._args              = [ "Esc" ];
						bind.SwitchToMode._args = [ "locked" ];
          }
          {
						bind._args              = [ "Enter" ];
						bind.SwitchToMode._args = [ "normal" ];
          }
          {
						bind._args         = [ "h" ];
						bind.MoveTab._args = [ "Left" ];
          }
          {
						bind._args         = [ "l" ];
						bind.MoveTab._args = [ "Right" ];
          }
          {
						bind._args  = [ "n" ];
						bind.NewTab = { };
          }
          {
						bind._args    = [ "x" ];
						bind.CloseTab = { };
          }
          {
            bind = {
              _args = [ "r" ];
              _children = [
                { SwitchToMode._args = [ "RenameTab" ]; }
                { TabNameInput._args = [ 0 ]; }
              ];
            };
          }
          {
						bind._args         = [ "1" ];
						bind.GoToTab._args = [ 1 ];
          }
          {
						bind._args         = [ "2" ];
						bind.GoToTab._args = [ 2 ];
          }
          {
						bind._args         = [ "3" ];
						bind.GoToTab._args = [ 3 ];
          }
          {
						bind._args         = [ "4" ];
						bind.GoToTab._args = [ 4 ];
          }
          {
						bind._args         = [ "5" ];
						bind.GoToTab._args = [ 5 ];
          }
        ];

        # Resize mode
        resize._children = [
          {
						bind._args              = [ "Esc" ];
						bind.SwitchToMode._args = [ "locked" ];
          }
          {
						bind._args              = [ "Enter" ];
						bind.SwitchToMode._args = [ "normal" ];
          }
          {
						bind._args        = [ "h" ];
						bind.Resize._args = [ "Increase Left" ];
          }
          {
						bind._args        = [ "j" ];
						bind.Resize._args = [ "Increase Down" ];
          }
          {
						bind._args        = [ "k" ];
						bind.Resize._args = [ "Increase Up" ];
          }
          {
						bind._args        = [ "l" ];
						bind.Resize._args = [ "Increase Right" ];
          }
          {
						bind._args        = [ "H" ];
						bind.Resize._args = [ "Decrease Left" ];
          }
          {
						bind._args        = [ "J" ];
						bind.Resize._args = [ "Decrease Down" ];
          }
          {
						bind._args        = [ "K" ];
						bind.Resize._args = [ "Decrease Up" ];
          }
          {
						bind._args        = [ "L" ];
						bind.Resize._args = [ "Decrease Right" ];
          }
          {
						bind._args        = [ "+" ];
						bind.Resize._args = [ "Increase" ];
          }
          {
						bind._args        = [ "-" ];
						bind.Resize._args = [ "Decrease" ];
          }
        ];

        # Scroll mode
        scroll._children = [
          {
						bind._args              = [ "Esc" ];
						bind.SwitchToMode._args = [ "locked" ];
          }
          {
						bind._args              = [ "Enter" ];
						bind.SwitchToMode._args = [ "normal" ];
          }
          {
						bind._args      = [ "j" ];
						bind.ScrollDown = { };
          }
          {
						bind._args    = [ "k" ];
						bind.ScrollUp = { };
          }
          {
						bind._args              = [ "d" ];
						bind.HalfPageScrollDown = { };
          }
          {
						bind._args            = [ "u" ];
						bind.HalfPageScrollUp = { };
          }
          {
						bind._args          = [ "e" ];
						bind.EditScrollback = { };
          }
        ];

        # Session mode
        session._children = [
          {
						bind._args              = [ "Esc" ];
						bind.SwitchToMode._args = [ "locked" ];
          }
          {
						bind._args              = [ "Enter" ];
						bind.SwitchToMode._args = [ "normal" ];
          }
          {
						bind._args  = [ "d" ];
						bind.Detach = { };
          }
          {
            bind = {
              _args     = [ "w" ];
              _children = [
                { SwitchToMode._args        = [ "normal" ]; }
                { LaunchOrFocusPlugin._args = [ "session-manager" "true" ]; }
              ];
            };
          }
        ];

        # rename tab mode
        RenameTab._children = [
          {
						bind._args              = [ "Esc" ];
						bind.SwitchToMode._args = [ "locked" ];
          }
          {
						bind._args     = [ "Enter" ];
						bind._children = [ { SwitchToMode._args = [ "locked" ]; } ];
          }
        ];

      };

      load_plugins = [
        "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
        "https://github.com/karimould/zellij-forgot/releases/latest/download/zellij_forgot.wasm"
      ];
      plugins.tab-bar.path     = "tab-bar";
			plugins.status-bar.path  = "status-bar";
			plugins.strider.path     = "strider";
			plugins.compact-bar.path = "compact-bar";

    };

    layouts = {
      james = ''
				layout {
					pane
					pane size=1 borderless=true {
						plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
							hide_frame_for_single_pane "true"

							format_left   "{mode} #[fg=gray]{session} {tabs}"
							format_center ""
							format_right  "{datetime}"
							format_space  ""

							mode_normal        "#[fg=#FFFFFF,bg=green] NORMAL "
							mode_locked        "#[fg=#FFFFFF,bg=red] LOCKED "

							tab_normal         "#[fg=#FFFFFF,bg=#7F7F7F] {index}:{name} "
							tab_active         "#[fg=#FFFFFF,bg=blue,bold] {index}:{name} "

							datetime           "#[fg=blue,bold] {format}"
							datetime_format		 "%H:%M"
							datetime_timezone  "Europe/Warsaw"

							command_git_branch_command		"git rev-parse --abbrev-ref HEAD"
							command_git_branch_format			"#[fg=blue]{stdout}"
							command_git_branch_interval		"10"
							command_git_branch_rendermode "static"

							command_cwd_command						"pwd"
							command_cwd_format						"#[fg=green] {stdout}"
							command_cwd_interval					"5"
							command_cwd_rendermode				"static"
						}
					}
				}
      '';
    };
  };
}
