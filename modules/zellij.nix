{
  flake.modules.common.zellij =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
      inherit (config) theme;
    in
    {
      shellAliases."zellij-ide" = "zellij action override-layout ~/.config/zellij/layouts/ide.kdl";

      hjem.extraModule =
        { osConfig, config, ... }:
        {
          packages = singleton pkgs.zellij;

          xdg.config.files = {
            "zellij/config.kdl".text =
              let
                modeTemplate = mode: modeFg: "#[fg=gray][#[fg=${modeFg}]${mode}#[fg=gray]] ";
              in
              with theme.withRgb; # kdl
              ''
                    theme "${if theme.colorScheme == "matugen" then "custom" else theme.zellij}"
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
                    scrollback_editor "${osConfig.environment.variables.EDITOR}"

                    default_layout "default"
                    session_serialization true
                    auto_layout true
                    mirror_session false
                    on_force_close "detach"
                    attach_to_session true

                    pane_frames false
                    simplified_ui false
                    show_startup_tips false
                    show_release_notes false

                    mouse_mode true
                    mouse_click_through true
                    focus_follows_mouse true
                    scroll_buffer_size 5000

                    copy_command "wl-copy"
                    copy_on_select false
                    copy_clipboard "system"

                    default_mode "locked"

                    pane_viewport_serialization true
                    scrollback_lines_to_serialize 5000

                    env.EDITOR "${osConfig.environment.variables.EDITOR}"
                    env.SHELL "${osConfig.environment.variables.SHELL}"

                    simplified_ui_default_plugin "compact-bar"
                    ui.pane_frames.hide_session_name false
                    ui.pane_frames.rounded_corners false

                    keybinds clear-defaults=true {
                      locked {
                        bind "Ctrl g" { SwitchToMode "normal"; }
                        bind "Alt h" { MoveFocus "Left"; }
                        bind "Alt k" { MoveFocus "Up"; }
                        bind "Alt j" { MoveFocus "Down"; }
                        bind "Alt l" { MoveFocus "Right"; }
                        bind "Alt -" { Resize "Decrease"; }
                        bind "Alt +" { Resize "Increase"; }
                        bind "Alt =" { Resize "Increase"; }
                      }

                      normal {
                        bind "q" { GoToTab 1; }
                        bind "w" { GoToTab 2; }
                        bind "e" { GoToTab 3; }
                        bind "r" { GoToTab 4; }
                        bind "t" { GoToTab 5; }
                        bind "y" { GoToTab 6; }
                        bind "u" { GoToTab 7; }
                        bind "i" { GoToTab 8; }
                        bind "o" { GoToTab 9; }
                        bind "Ctrl g" {
                          Run "${getExe pkgs.jjui}" {
                            in_place true
                            close_on_exit true
                          };
                          SwitchToMode "locked";
                        }
                        bind "Ctrl d" {
                          Run "${getExe pkgs.discordo}" {
                            in_place true
                            close_on_exit true
                          };
                          SwitchToMode "locked";
                        }
                        bind "Ctrl s" {
                          Run "${getExe pkgs.lf}" {
                            in_place true
                            close_on_exit true
                          };
                          SwitchToMode "locked";
                        }
                        bind "Ctrl p" {
                          LaunchOrFocusPlugin "sessionizer" {
                            floating true
                            move_to_focused_tab true
                            cwd "/"
                            root_dirs "${config.directory}/projects"
                            individual_dirs "${config.directory}/nixos;${config.directory}/notes"
                            ignore_dirs "${config.directory}/projects/docpad"
                            session_layout "default"
                          }
                          SwitchToMode "locked";
                        }
                      }

                      pane {
                        bind "d" { NewPane "Down"; SwitchToMode "locked"; }
                        bind "r" { NewPane "Right"; SwitchToMode "locked"; }
                        bind "x" { CloseFocus; }
                        bind "f" { ToggleFocusFullscreen; }
                        bind "w" { ToggleFloatingPanes; }
                        bind "h" { MovePane "Left"; }
                        bind "j" { MovePane "Down"; }
                        bind "k" { MovePane "Up"; }
                        bind "l" { MovePane "Right"; }
                      }

                      tab {
                        bind "h" { MoveTab "Left"; }
                        bind "l" { MoveTab "Right"; }
                        bind "n" { NewTab; }
                        bind "x" { CloseTab; }
                      }

                      resize {
                        bind "h" { Resize "Increase Left"; }
                        bind "j" { Resize "Increase Down"; }
                        bind "k" { Resize "Increase Up"; }
                        bind "l" { Resize "Increase Right"; }
                        bind "+" { Resize "Increase"; }
                        bind "-" { Resize "Decrease"; }
                      }

                      scroll {
                        bind "j" { ScrollDown; }
                        bind "k" { ScrollUp; }
                        bind "d" { HalfPageScrollDown; }
                        bind "u" { HalfPageScrollUp; }
                        bind "e" { EditScrollback; }
                      }

                      session {
                        bind "d" { Detach; }
                        bind "w" {
                          SwitchToMode "locked";
                          LaunchOrFocusPlugin "session-manager" "true";
                        }
                      }

                      shared_except "locked" {
                        bind "Esc" "Enter" { SwitchToMode "locked"; }
                      }

                      shared_except "pane" "locked" {
                        bind "Ctrl w" { SwitchToMode "pane"; }
                      }

                      shared_except "tab" "locked" {
                        bind "Ctrl t" { SwitchToMode "tab"; }
                      }

                      shared_except "resize" "locked" {
                        bind "Ctrl r" { SwitchToMode "resize"; }
                      }

                      shared_except "scroll" "locked" {
                        bind "Ctrl s" { SwitchToMode "scroll"; }
                      }

                      shared_except "session" "locked" {
                        bind "Ctrl o" { SwitchToMode "session"; }
                      }
                    }

                    load_plugins {
                      sessionizer
                      attention
                      zjstatus
                      zjstatus-hints
                    };

                    plugins {
                      tab-bar location="zellij:tab-bar"
                      status-bar location="zellij:status-bar"
                      strider location="zellij:strider"
                      compact-bar location="zellij:compact-bar"
                      plugin-manager location="zellij:plugin-manager"

                      sessionizer location="file:/home/jam/projects/zellij-sessionizer/target/wasm32-wasip1/debug/zellij-sessionizer.wasm"

                      attention location="https://github.com/KiryuuLight/zellij-attention/releases/latest/download/zellij-attention.wasm"

                      zjstatus location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
                    		hide_frame_for_single_pane "false"

                    		format_left "{mode}#[fg=gray]{session}"
                    		format_center "{tabs}"
                    		format_right "{pipe_zjstatus_hints}"
                    		format_space ""

                        pipe_zjstatus_hints_format "{output}"

                  		  // Gives gray [ ] and coloured mode.
                  		  mode_normal "${modeTemplate "NOR" "#b8bb26"}"
                  		  mode_locked "${modeTemplate "LOC" "#fb4934"}"
                  		  mode_pane "${modeTemplate "PAN" "#83a598"}"
                  		  mode_tab "${modeTemplate "TAB" "#d3869b"}"
                  		  mode_rename "${modeTemplate "REN" "#fabd2f"}"
                  		  mode_resize "${modeTemplate "RES" "#8ec07c"}"
                  		  mode_scroll "${modeTemplate "SCR" "#fe8019"}"
                  		  mode_session "${modeTemplate "SES" "#d65d0e"}"

                  		  tab_normal "#[fg=#d5c4a1]{index}:{name} "
                  		  tab_active "#[fg=#83a598,bold]{index}:{name}* "
                		  }

                      zjstatus-hints location="https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm" {
                        max_length 0
                        overflow_str "..."
                        pipe_name "zjstatus_hints"
                        hide_in_base_mode false
                      }
                    }
              '';

            "zellij/layouts/default.kdl".text =
              # kdl
              ''
                layout {
                  default_tab_template {
                    children
                    pane size=1 borderless=true {
                      plugin location="zjstatus"
                    }
                  }
                }
              '';

            "zellij/layouts/ide.kdl".text = # kdl
              ''
                layout {
                  pane size="75%" split_direction="vertical" {
                      pane focus=true size="75%"
                      pane size="25%"
                  }
                  pane size="25%" split_direction="vertical" {
                      pane size="50%"
                      pane size="50%"
                  }
                  pane size=1 borderless=true {
                    plugin location="zjstatus"
                  }
                }
              '';
          };

          # This is so much nicer than having to approve permissions.
          # Grep "permission" in the plugin repo to find them.
          xdg.cache.files."zellij/permissions.kdl".text = # kdl
            ''
              "https://github.com/plumj-am/zellij-sessionizer/releases/latest/download/zellij-sessionizer.wasm" {
                  ReadApplicationState
                  ChangeApplicationState
                  RunCommands
              }
              "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
                  ChangeApplicationState
                  ReadApplicationState
                  RunCommands
              }
              "https://github.com/KiryuuLight/zellij-attention/releases/latest/download/zellij-attention.wasm" {
                  ReadCliPipes
                  MessageAndLaunchOtherPlugins
                  ChangeApplicationState
                  ReadApplicationState
              }
              "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm" {
                  MessageAndLaunchOtherPlugins
                  ReadApplicationState
              }
            '';
        };
    };
}
