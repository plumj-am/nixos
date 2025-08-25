let
  dark_theme = "gruvbox-dark";
  light_theme = "gruvbox-light";
in
{
  programs.zellij = {
    enable = true;

    # Shell integration
    enableBashIntegration = true;

    # Session behavior
    attachExistingSession = true;
    exitShellOnExit = false;

    settings = {
      # Theme and appearance
      theme = light_theme;

      # Shell and editor
      default_shell = "nu";
      scrollback_editor = "nvim";

      # Layout and sessions
      default_layout = "james";
      session_serialization = true;
      auto_layout = true;

      # UI settings
      pane_frames = false;
      simplified_ui = true;
      show_startup_tips = false;

      # Mouse and interaction
      mouse_mode = false;
      scroll_buffer_size = 5000;

      # Copy/paste
      copy_on_select = false;
      copy_clipboard = "system";

      # Mode and navigation
      default_mode = "locked";

      # Performance
      pane_viewport_serialization = true;
      scrollback_lines_to_serialize = 5000;

      # Environment
      env = {
        EDITOR = "nvim";
        SHELL = "nu";
      };

      # UI components

      # Advanced
      mirror_session = false;

      on_force_close = "detach";
      simplified_ui_default_plugin = "compact-bar";

      # Custom keybinds
      keybinds = {
        _props.clear-defaults = true;

        # Locked mode (minimal interference)
        locked._children = [
          {
            bind = {
              _args = [ "Ctrl g" ];
              SwitchToMode._args = [ "normal" ];
            };
          }
        ];

        # Normal mode
        normal._children = [
          {
            bind = {
              _args = [ "Esc" ];
              SwitchToMode._args = [ "locked" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl p" ];
              SwitchToMode._args = [ "pane" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl t" ];
              SwitchToMode._args = [ "tab" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl r" ];
              SwitchToMode._args = [ "resize" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl s" ];
              SwitchToMode._args = [ "scroll" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl o" ];
              SwitchToMode._args = [ "session" ];
            };
          }
          # {
          #   bind = {
          #     _args = [ "Ctrl q" ];
          #     Quit = { };
          #   };
          # }
          {
            bind = {
              _args = [ "Ctrl h" ];
              MoveFocus = [ "Left" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl l" ];
              MoveFocus = [ "Right" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl j" ];
              MoveFocus = [ "Down" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl k" ];
              MoveFocus = [ "Up" ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl x" ];
              CloseFocus = { };
            };
          }
          {
            bind = {
              _args = [ "H" ];
              GoToPreviousTab = { };
            };
          }
          {
            bind = {
              _args = [ "L" ];
              GoToNextTab = { };
            };
          }
          {
            bind = {
              _args = [ "Ctrl f" ];
              _children = [
                {
                  LaunchOrFocusPlugin = {
                    _args = [
                      "https://github.com/karimould/zellij-forgot/releases/latest/download/zellij_forgot.wasm"
                    ];
                    floating = true;
                  };
                }
              ];
            };
          }
          {
            bind = {
              _args = [ "q" ];
              GoToTab._args = [ 1 ];
            };
          }
          {
            bind = {
              _args = [ "w" ];
              GoToTab._args = [ 2 ];
            };
          }
          {
            bind = {
              _args = [ "e" ];
              GoToTab._args = [ 3 ];
            };
          }
          {
            bind = {
              _args = [ "r" ];
              GoToTab._args = [ 4 ];
            };
          }
          {
            bind = {
              _args = [ "t" ];
              GoToTab._args = [ 5 ];
            };
          }
          {
            bind = {
              _args = [ "y" ];
              GoToTab._args = [ 6 ];
            };
          }
          {
            bind = {
              _args = [ "u" ];
              GoToTab._args = [ 7 ];
            };
          }
          {
            bind = {
              _args = [ "i" ];
              GoToTab._args = [ 8 ];
            };
          }
          {
            bind = {
              _args = [ "o" ];
              GoToTab._args = [ 9 ];
            };
          }
        ];

        # Pane mode
        pane._children = [
          {
            bind = {
              _args = [ "Esc" ];
              SwitchToMode._args = [ "locked" ];
            };
          }
          {
            bind = {
              _args = [ "Enter" ];
              SwitchToMode._args = [ "normal" ];
            };
          }
          {
            bind = {
              _args = [ "h" ];
              MoveFocus = [ "Left" ];
            };
          }
          {
            bind = {
              _args = [ "l" ];
              MoveFocus = [ "Right" ];
            };
          }
          {
            bind = {
              _args = [ "j" ];
              MoveFocus = [ "Down" ];
            };
          }
          {
            bind = {
              _args = [ "k" ];
              MoveFocus = [ "Up" ];
            };
          }
          {
            bind = {
              _args = [ "n" ];
              NewPane = { };
            };
          }
          {
            bind = {
              _args = [ "d" ];
              NewPane._args = [ "Down" ];
            };
          }
          {
            bind = {
              _args = [ "r" ];
              NewPane._args = [ "Right" ];
            };
          }
          {
            bind = {
              _args = [ "x" ];
              CloseFocus = { };
            };
          }
          {
            bind = {
              _args = [ "f" ];
              ToggleFocusFullscreen = { };
            };
          }
          {
            bind = {
              _args = [ "z" ];
              TogglePaneFrames = { };
            };
          }
          {
            bind = {
              _args = [ "w" ];
              ToggleFloatingPanes = { };
            };
          }
        ];

        # Tab mode
        tab._children = [
          {
            bind = {
              _args = [ "Esc" ];
              SwitchToMode._args = [ "locked" ];
            };
          }
          {
            bind = {
              _args = [ "Enter" ];
              SwitchToMode._args = [ "normal" ];
            };
          }
          {
            bind = {
              _args = [ "h" ];
              MoveTab._args = [ "Left" ];
            };
          }
          {
            bind = {
              _args = [ "l" ];
              MoveTab._args = [ "Right" ];
            };
          }
          {
            bind = {
              _args = [ "n" ];
              NewTab = { };
            };
          }
          {
            bind = {
              _args = [ "x" ];
              CloseTab = { };
            };
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
            bind = {
              _args = [ "1" ];
              GoToTab._args = [ 1 ];
            };
          }
          {
            bind = {
              _args = [ "2" ];
              GoToTab._args = [ 2 ];
            };
          }
          {
            bind = {
              _args = [ "3" ];
              GoToTab._args = [ 3 ];
            };
          }
          {
            bind = {
              _args = [ "4" ];
              GoToTab._args = [ 4 ];
            };
          }
          {
            bind = {
              _args = [ "5" ];
              GoToTab._args = [ 5 ];
            };
          }
        ];

        # Resize mode
        resize._children = [
          {
            bind = {
              _args = [ "Esc" ];
              SwitchToMode._args = [ "locked" ];
            };
          }
          {
            bind = {
              _args = [ "Enter" ];
              SwitchToMode._args = [ "normal" ];
            };
          }
          {
            bind = {
              _args = [ "h" ];
              Resize._args = [ "Increase Left" ];
            };
          }
          {
            bind = {
              _args = [ "j" ];
              Resize._args = [
                "Increase Down"
              ];
            };
          }
          {
            bind = {
              _args = [ "k" ];
              Resize._args = [
                "Increase Up"
              ];
            };
          }
          {
            bind = {
              _args = [ "l" ];
              Resize._args = [
                "Increase Right"
              ];
            };
          }
          {
            bind = {
              _args = [ "H" ];
              Resize._args = [
                "Decrease Left"
              ];
            };
          }
          {
            bind = {
              _args = [ "J" ];
              Resize._args = [
                "Decrease Down"
              ];
            };
          }
          {
            bind = {
              _args = [ "K" ];
              Resize._args = [
                "Decrease Up"
              ];
            };
          }
          {
            bind = {
              _args = [ "L" ];
              Resize._args = [
                "Decrease Right"
              ];
            };
          }
          {
            bind = {
              _args = [ "+" ];
              Resize._args = [ "Increase" ];
            };
          }
          {
            bind = {
              _args = [ "-" ];
              Resize._args = [ "Decrease" ];
            };
          }
        ];

        # Scroll mode
        scroll._children = [
          {
            bind = {
              _args = [ "Esc" ];
              SwitchToMode._args = [ "locked" ];
            };
          }
          {
            bind = {
              _args = [ "Enter" ];
              SwitchToMode._args = [ "normal" ];
            };
          }
          {
            bind = {
              _args = [ "j" ];
              ScrollDown = { };
            };
          }
          {
            bind = {
              _args = [ "k" ];
              ScrollUp = { };
            };
          }
          {
            bind = {
              _args = [ "d" ];
              HalfPageScrollDown = { };
            };
          }
          {
            bind = {
              _args = [ "u" ];
              HalfPageScrollUp = { };
            };
          }
          {
            bind = {
              _args = [ "e" ];
              EditScrollback = { };
            };
          }
        ];

        # Session mode
        session._children = [
          {
            bind = {
              _args = [ "Esc" ];
              SwitchToMode._args = [ "locked" ];
            };
          }
          {
            bind = {
              _args = [ "Enter" ];
              SwitchToMode._args = [ "normal" ];
            };
          }
          {
            bind = {
              _args = [ "d" ];
              Detach = { };
            };
          }
          {
            bind = {
              _args = [ "w" ];
              _children = [
                { SwitchToMode._args = [ "normal" ]; }
                {
                  LaunchOrFocusPlugin._args = [
                    "session-manager"
                    "true"
                  ];
                }
              ];
            };
          }
        ];

        # rename tab mode
        RenameTab._children = [
          {
            bind = {
              _args = [ "Esc" ];
              SwitchToMode._args = [ "locked" ];
            };
          }
          {
            bind = {
              _args = [ "Enter" ];
              _children = [
                { SwitchToMode._args = [ "locked" ]; }
              ];
            };
          }
        ];
      };

      load_plugins = [
        "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
        "https://github.com/karimould/zellij-forgot/releases/latest/download/zellij_forgot.wasm"

      ];
      plugins = {
        tab-bar = {
          path = "tab-bar";
        };
        status-bar = {
          path = "status-bar";
        };
        strider = {
          path = "strider";
        };
        compact-bar = {
          path = "compact-bar";
        };
      };

      ui = {
        pane_frames = {
          hide_session_name = false;
          rounded_corners = false;
        };
      };
    };

    layouts = {
      compact = ''
        layout {
          pane
          pane size=1 borderless=true {
            plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
              format_left   "{mode} {session}"
              format_center "{tabs}"
              format_right  "{datetime}"

              mode_normal        "#[bg=blue] NORMAL (Esc to lock) "
              mode_locked        "#[bg=green] LOCKED "

              tab_normal         "#[fg=gray] {name} "
              tab_active         "#[fg=blue,bold] {name} "

              datetime           "#[fg=gray,italic]{%H:%M}"
            }
          }
        }
      '';

      dev = ''
        layout {
          pane split_direction="vertical" {
            pane
            pane size="30%"
          }
          pane size=1 borderless=true {
            plugin location="zjstatus" {
              format_left   "{mode} {session}"
              format_center "{tabs}"
              format_right  "{datetime}"

              mode_normal        "#[bg=blue] NORMAL (Esc to lock) "
              mode_locked        "#[bg=green] LOCKED "

              tab_normal         "#[fg=gray] {name} "
              tab_active         "#[fg=blue,bold] {name} "

              datetime           "#[fg=gray,italic]{%H:%M}"
            }
          }
        }
      '';

      editor = ''
        layout {
          pane split_direction="horizontal" {
            pane size="80%"
            pane split_direction="vertical" {
              pane
              pane
            }
          }
          pane size=1 borderless=true {
            plugin location="zjstatus" {
              format_left   "{mode} {session}"
              format_center "{tabs}"
              format_right  "{datetime}"

              mode_normal        "#[bg=blue] NORMAL (Esc to lock) "
              mode_locked        "#[bg=green] LOCKED "

              tab_normal         "#[fg=gray] {name} "
              tab_active         "#[fg=blue,bold] {name} "

              datetime           "#[fg=gray,italic]{%H:%M}"
            }
          }
        }
      '';

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

                        			tab_normal         "#[fg=#FFFFFF,bg=#7F7F7F] {index} :: {name} "
                        			tab_active         "#[fg=#FFFFFF,bg=blue,bold] {index} :: {name} "

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
