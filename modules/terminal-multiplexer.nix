{
  config.flake.modules.hjem.terminal-multiplexer =
    {
      pkgs,
      config,
      theme,
      ...
    }:
    {
      packages = [
        pkgs.zellij

        (pkgs.writeTextFile {
          name = "zellij-kitty";
          destination = "/share/applications/zellij-kitty.desktop";
          text = ''
            [Desktop Entry]
            Name=Zellij kitty
            Icon=kitty
            Exec=kitty ${pkgs.zellij}/bin/zellij
            Terminal=false
          '';
        })
      ];

      xdg.config.files."zellij/config.kdl".text =
        with theme.withRgb; # kdl
        ''
          theme "${if theme.color_scheme == "pywal" then "custom" else theme.zellij}"
          themes {
            custom {
              bg ${toString base00}
              fg ${toString base06}
              red ${toString base08}
              green ${toString base0B}
              yellow ${toString base0A}
              blue ${toString base0D}
              magenta ${toString base0E}
              orange ${toString base09}
              cyan ${toString base0C}
              black ${toString base01}
              white ${toString base05}
            }
          }

          default_shell "nu"
          scrollback_editor "${config.environment.sessionVariables.EDITOR}"

          default_layout "plumjam"
          session_serialization true
          auto_layout true
          mirror_session false
          on_force_close "detach"

          pane_frames false
          simplified_ui true
          show_startup_tips false

          mouse_mode false
          scroll_buffer_size 5000

          copy_on_select false
          copy_clipboard "system"

          default_mode "locked"

          pane_viewport_serialization true
          scrollback_lines_to_serialize 5000

          env.EDITOR "${config.environment.sessionVariables.EDITOR}"
          env.SHELL "nu"

          simplified_ui_default_plugin "compact-bar"
          ui.pane_frames.hide_session_name false
          ui.pane_frames.rounded_corners false

          keybinds clear-defaults=true {

            locked {
              bind "Ctrl g" { SwitchToMode "normal"; }
            }

            normal {
              bind "Esc" { SwitchToMode "locked"; }
              bind "Enter" { SwitchToMode "locked"; }
              bind "Ctrl w" { SwitchToMode "pane"; }
              bind "Ctrl t" { SwitchToMode "tab"; }
              bind "Ctrl r" { SwitchToMode "resize"; }
              bind "Ctrl s" { SwitchToMode "scroll"; }
              bind "Ctrl o" { SwitchToMode "session"; }
              bind "Ctrl h" { MoveFocus "Left"; SwitchToMode "locked"; }
              bind "Ctrl j" { MoveFocus "Down"; SwitchToMode "locked"; }
              bind "Ctrl k" { MoveFocus "Up"; SwitchToMode "locked"; }
              bind "Ctrl l" { MoveFocus "Right"; SwitchToMode "locked"; }
              bind "q" { GoToTab 1; }
              bind "w" { GoToTab 2; }
              bind "e" { GoToTab 3; }
              bind "r" { GoToTab 4; }
              bind "t" { GoToTab 5; }
              bind "y" { GoToTab 6; }
              bind "u" { GoToTab 7; }
              bind "i" { GoToTab 8; }
              bind "o" { GoToTab 9; }
              bind "H" { GoToPreviousTab; }
              bind "L" { GoToNextTab; }
              bind "g" {
                Run "nu" "--commands" "repo" {
                  close_on_exit true
                  floating true
                  x "1%"
                  y "1%"
                  width "1%"
                  height "1%"
                };
                SwitchToMode "locked";
              }
              bind "Ctrl n" {
                Run "nu" {
                  close_on_exit true
                  floating true
                  x "5%"
                  y "5%"
                  width "90%"
                  height "90%"
                };
                SwitchToMode "locked";
              }
              bind "Ctrl p" {
                LaunchOrFocusPlugin "https://github.com/laperlej/zellij-sessionizer/releases/latest/download/zellij-sessionizer.wasm" {
                  floating true
                  move_to_focused_tab true
                  cwd "/"
                  root_dirs "/home/jam;/home/jam/projects;/home/jam/notes"
                  session_layout "plumjam"
                };
                SwitchToMode "locked";
              }
            }

            pane {
              bind "Esc" { SwitchToMode "locked"; }
              bind "Enter" { SwitchToMode "locked"; }
              bind "h" { MoveFocus "Left"; }
              bind "j" { MoveFocus "Up"; }
              bind "k" { MoveFocus "Down"; }
              bind "l" { MoveFocus "Right"; }
              bind "n" { NewPane; }
              bind "d" { NewPane "Down"; }
              bind "r" { NewPane "Right"; }
              bind "x" { CloseFocus; }
              bind "f" { ToggleFocusFullscreen; }
              bind "z" { TogglePaneFrames; }
              bind "w" { ToggleFloatingPanes; }
            }

            tab {
              bind "Esc" { SwitchToMode "locked"; }
              bind "Enter" { SwitchToMode "locked"; }
              bind "h" { MoveTab "Left"; }
              bind "l" { MoveTab "Right"; }
              bind "n" { NewTab; }
              bind "x" { CloseTab; }
              bind "r" {
                SwitchToMode "RenameTab";
                TabNameInput 0;
              }
            }

            resize {
              bind "Esc" { SwitchToMode "locked"; }
              bind "Enter" { SwitchToMode "locked"; }
              bind "h" { Resize "Increase Left"; }
              bind "j" { Resize "Increase Down"; }
              bind "k" { Resize "Increase Up"; }
              bind "l" { Resize "Increase Right"; }
              bind "H" { Resize "Decrease Left"; }
              bind "J" { Resize "Decrease Down"; }
              bind "K" { Resize "Decrease Up"; }
              bind "L" { Resize "Decrease Right"; }
              bind "+" { Resize "Increase"; }
              bind "-" { Resize "Decrease"; }
            }

            scroll {
              bind "Esc" { SwitchToMode "locked"; }
              bind "Enter" { SwitchToMode "locked"; }
              bind "j" { ScrollDown; }
              bind "k" { ScrollUp; }
              bind "d" { HalfPageScrollDown; }
              bind "u" { HalfPageScrollUp; }
              bind "e" { EditScrollback; }
            }

            session {
              bind "Esc" { SwitchToMode "locked"; }
              bind "Enter" { SwitchToMode "locked"; }
              bind "d" { Detach; }
              bind "w" {
                SwitchToMode "locked";
                LaunchOrFocusPlugin "session-manager" "true";
              }
            }

            "RenameTab" {
              bind "Esc" { SwitchToMode "locked"; }
              bind "Enter" { SwitchToMode "locked"; }
            }
          }

          load_plugins {
            "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
            "https://github.com/laperlej/zellij-sessionizer/releases/latest/download/zellij-sessionizer.wasm"
          };

          plugins {
            tab-bar location="zellij:tab-bar"
            status-bar location="zellij:status-bar"
            strider location="zellij:strider"
            compact-bar location="zellij:compact-bar"
          }
        '';
    };
}
