{ config, lib, ... }: let
	inherit (lib) enabled mkIf;

	# Simple Zellij key-binding helper.
	key = k: action: {
		bind = {
			_args = [ k ];
		} // action;
	};

	# Nested Zellij key-binding helper for plugins and similar.
	keyPlugin = k: children: {
		bind._args = [ k ];
		bind._children = children;
	};
in {
  environment.shellAliases = {
    dev = "zellij-dev-tab";
  };

  home-manager.sharedModules = [{
    programs.zellij = with config.theme.withHash; mkIf config.isDesktop (enabled {
      enableBashIntegration = true;

      attachExistingSession = true;
      exitShellOnExit       = false;

      settings = {
      theme = config.theme.zellij;

      default_shell     = "nu";
      scrollback_editor = config.environment.variables.EDITOR;

      default_layout        = "plumjam";
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

      env.EDITOR = config.environment.variables.EDITOR;
			env.SHELL  = "nu";

      simplified_ui_default_plugin     = "compact-bar";
      ui.pane_frames.hide_session_name = false;
			ui.pane_frames.rounded_corners   = false;

      keybinds = {
        _props.clear-defaults = true;

        # Locked mode.
        locked._children = [
          (key "Ctrl g" { SwitchToMode._args = [ "normal" ]; })
        ];

        # Normal mode.
        normal._children = [
          (key "Esc"    { SwitchToMode._args = [ "locked" ]; })
          (key "Ctrl w" { SwitchToMode._args = [ "pane" ]; })
          (key "Ctrl t" { SwitchToMode._args = [ "tab" ]; })
          (key "Ctrl r" { SwitchToMode._args = [ "resize" ]; })
          (key "Ctrl s" { SwitchToMode._args = [ "scroll" ]; })
          (key "Ctrl o" { SwitchToMode._args = [ "session" ]; })
          (key "Ctrl h" { MoveFocus = [ "Left" ]; })
          (key "Ctrl j" { MoveFocus = [ "Down" ]; })
          (key "Ctrl k" { MoveFocus = [ "Up" ]; })
          (key "Ctrl l" { MoveFocus = [ "Right" ]; })
          (key "q"      { GoToTab._args = [ 1 ];})
          (key "w"      { GoToTab._args = [ 2 ];})
          (key "e"      { GoToTab._args = [ 3 ];})
          (key "r"      { GoToTab._args = [ 4 ];})
          (key "t"      { GoToTab._args = [ 5 ];})
          (key "y"      { GoToTab._args = [ 6 ];})
          (key "u"      { GoToTab._args = [ 7 ];})
          (key "i"      { GoToTab._args = [ 8 ];})
          (key "o"      { GoToTab._args = [ 9 ];})
          (key "H"      { GoToPreviousTab = {}; })
          (key "L"      { GoToNextTab = {}; })
          (keyPlugin "Ctrl f" [{
            LaunchOrFocusPlugin = {
              _args = [ "https://github.com/karimould/zellij-forgot/releases/latest/download/zellij_forgot.wasm" ];
              floating = true;
            };
          }])
          (keyPlugin "Ctrl j" [{
            Run = {
              _args         = [ "lazyjj" ];
              close_on_exit = true;
              floating      = true;
              x             = "5%";
              y             = "5%";
              width         = "90%";
              height        = "90%";
            };
          }])
          (keyPlugin "Ctrl n" [{
            Run = {
              _args         = [ "nu" ];
              close_on_exit = true;
              floating      = true;
              x             = "5%";
              y             = "5%";
              width         = "90%";
              height        = "90%";
            };
          }])
        ];

        # Pane mode.
        pane._children = [
          (key "Esc"   { SwitchToMode._args = [ "locked" ];})
          (key "Enter" { SwitchToMode._args = [ "normal" ];})
          (key "h"     { MoveFocus = [ "Left" ];})
          (key "j"     { MoveFocus = [ "Up" ];})
          (key "k"     { MoveFocus = [ "Down" ];})
          (key "l"     { MoveFocus = [ "Right" ];})
          (key "n"     { NewPane = {};})
          (key "d"     { NewPane._args = [ "Down" ];})
          (key "r"     { NewPane._args = [ "Right" ];})
          (key "x"     { CloseFocus = {};})
          (key "f"     { ToggleFocusFullscreen = {};})
          (key "z"     { TogglePaneFrames = {};})
          (key "w"     { ToggleFloatingPanes = {};})
        ];

        # Tab mode.
        tab._children = [
          (key "Esc"   { SwitchToMode._args = [ "locked" ]; })
          (key "Enter" { SwitchToMode._args = [ "normal" ]; })
          (key "h"     { MoveTab._args = [ "Left" ]; })
          (key "l"     { MoveTab._args = [ "Right" ]; })
          (key "n"     { NewTab = {}; })
          (key "x"     { CloseTab = {}; })
          (key "1"     { GoToTab._args = [ 1 ]; })
          (key "2"     { GoToTab._args = [ 2 ]; })
          (key "3"     { GoToTab._args = [ 3 ]; })
          (key "4"     { GoToTab._args = [ 4 ]; })
          (key "5"     { GoToTab._args = [ 5 ]; })
          (keyPlugin "r" [
            { SwitchToMode._args = [ "RenameTab" ]; }
            { TabNameInput._args = [ 0 ]; }
          ])
        ];

        # Resize mode.
        resize._children = [
          (key "Esc"   { SwitchToMode._args = [ "locked" ]; })
          (key "Enter" { SwitchToMode._args = [ "normal" ]; })
          (key "h"     { Resize._args = [ "Increase Left" ]; })
          (key "j"     { Resize._args = [ "Increase Down" ]; })
          (key "k"     { Resize._args = [ "Increase Up" ]; })
          (key "l"     { Resize._args = [ "Increase Right" ]; })
          (key "H"     { Resize._args = [ "Decrease Left" ]; })
          (key "J"     { Resize._args = [ "Decrease Down" ]; })
          (key "K"     { Resize._args = [ "Decrease Up" ]; })
          (key "L"     { Resize._args = [ "Decrease Right" ]; })
          (key "+"     { Resize._args = [ "Increase" ]; })
          (key "-"     { Resize._args = [ "Decrease" ]; })
        ];

        # Scroll mode.
        scroll._children = [
          (key "Esc"   { SwitchToMode._args = [ "locked" ]; })
          (key "Enter" { SwitchToMode._args = [ "normal" ]; })
          (key "j"     { ScrollDown = {}; })
          (key "k"     { ScrollUp = {}; })
          (key "d"     { HalfPageScrollDown = {}; })
          (key "u"     { HalfPageScrollUp = {}; })
          (key "e"     { EditScrollback = {}; })
        ];

        # Session mode.
        session._children = [
          (key "Esc"   { SwitchToMode._args = [ "locked" ]; })
          (key "Enter" { SwitchToMode._args = [ "normal" ]; })
          (key "d"     { Detach = {}; })
          (keyPlugin "w" [
            { SwitchToMode._args = [ "normal" ]; }
            { LaunchOrFocusPlugin._args = [ "session-manager" "true" ]; }
          ])
        ];

        # Rename tab mode.
        RenameTab._children = [
          (key "Esc"         { SwitchToMode._args = [ "locked" ]; })
          (keyPlugin "Enter" [ { SwitchToMode._args = [ "locked" ]; }
          ])
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
      plumjam = ''
				layout {
					pane
					pane size=1 borderless=true {
						plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
							hide_frame_for_single_pane "true"

							format_left   "{mode} #[fg=gray]{session} {tabs}"
							format_center ""
							format_right  "{datetime}"
							format_space  ""

							mode_normal        "#[fg=${base00},bg=${base0B}] NORMAL "
							mode_locked        "#[fg=${base00},bg=${base08}] LOCKED "

							tab_normal         "#[fg=${base05},bg=${base02}] {index}:{name} "
							tab_active         "#[fg=${base00},bg=${base0D},bold] {index}:{name} "

							datetime           "#[fg=${base0D},bold] {format}"
							datetime_format		 "%H:%M"
							datetime_timezone  "Europe/Warsaw"
						}
					}
				}
      '';

      dev = ''
        layout {
          pane split_direction="vertical" {
            pane size="70%"
            pane size="30%"
          }
					pane size=1 borderless=true {
						plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
							hide_frame_for_single_pane "false"

							format_left   "{mode} #[fg=gray]{session} {tabs}"
							format_center ""
							format_right  "{datetime}"
							format_space  ""

							mode_normal        "#[fg=${base00},bg=${base0B}] NORMAL "
							mode_locked        "#[fg=${base00},bg=${base08}] LOCKED "

							tab_normal         "#[fg=${base05},bg=${base02}] {index}:{name} "
							tab_active         "#[fg=${base00},bg=${base0D},bold] {index}:{name} "

							datetime           "#[fg=${base0D},bold] {format}"
							datetime_format		 "%H:%M"
							datetime_timezone  "Europe/Warsaw"
						}
					}
        }
      '';
      };
    });
  }];
}
