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

      # This is probably ass, I just asked the slop machine to do it and it works lol.
      # https://github.com/zellij-org/zellij/pull/5049
      zellij-patched = pkgs.zellij.overrideAttrs (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          patch -p1 < ${
            pkgs.fetchurl {
              url = "https://github.com/zellij-org/zellij/pull/5049.diff";
              hash = "sha256-qkC9if+TCWE8jLqRcfrALcvxE773N3KqWzDIY8jBb+A=";
            }
          }
        '';
      });
    in
    {
      shellAliases = {
        "zellij-ide" = "zellij --layout ~/.config/zellij/layouts/ide.kdl";
        "zellij-3t2b" = "zellij --layout ~/.config/zellij/layouts/3t2b.kdl";
        "zellij-detach" = "zellij action detach";
      };

      hjem.extraModule =
        { osConfig, config, ... }:
        {
          packages = singleton zellij-patched;

          xdg.config.files = {
            "zellij/config.kdl".text =
              let
                modeTemplate = mode: modeBg: "#[bg=${modeBg},fg=#ebdbb2,bold] ${mode} ";
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
                    scroll_buffer_size 50000

                    copy_on_select true
                    copy_clipboard "system"

                    default_mode "locked"

                    pane_viewport_serialization true
                    scrollback_lines_to_serialize 0

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
                        bind "Alt f" { ToggleFocusFullscreen; }
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
                        bind "Ctrl e" {
                          Run "${getExe pkgs.nnn}" {
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
                            session_layout "default"
                          }
                          SwitchToMode "locked";
                        }
                      }

                      move {
                        bind "n" { MovePane; }
                        bind "p" { MovePaneBackwards; }
                        bind "h" { MovePane "Left"; }
                        bind "j" { MovePane "Down"; }
                        bind "k" { MovePane "Up"; }
                        bind "l" { MovePane "Right"; }
                      }

                      pane {
                        bind "d" { NewPane "Down"; SwitchToMode "locked"; }
                        bind "r" { NewPane "Right"; SwitchToMode "locked"; }
                        bind "n" { NewPane "Stacked"; SwitchToMode "locked"; }
                        bind "x" { CloseFocus; }
                        bind "f" { ToggleFocusFullscreen; }
                        bind "w" { ToggleFloatingPanes; }
                      }

                      tab {
                        bind "h" { MoveTab "Left"; }
                        bind "l" { MoveTab "Right"; }
                        bind "n" { NewTab; }
                        bind "x" { CloseTab; }
                        bind "r" { SwitchToMode "renametab"; }
                        bind "p" { SwitchToMode "renamepane"; }
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

                      shared_except "move" "locked" {
                        bind "Ctrl m" { SwitchToMode "move"; }
                      }

                      shared_except "tab" "locked" {
                        bind "Ctrl t" { SwitchToMode "tab"; }
                      }

                      shared_except "resize" "locked" {
                        bind "Ctrl r" { SwitchToMode "resize"; }
                      }

                      shared_except "entersearch" "locked" {
                        bind "/" { SwitchToMode "entersearch"; }
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

                      // sessionizer location="file:/home/jam/projects/zellij-sessionizer/target/wasm32-wasip1/debug/zellij-sessionizer.wasm"
                      sessionizer location="https://github.com/plumj-am/zellij-sessionizer/releases/latest/download/zellij-sessionizer.wasm"

                      attention location="https://github.com/KiryuuLight/zellij-attention/releases/latest/download/zellij-attention.wasm"

                      zjstatus location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
                    		hide_frame_for_single_pane "false"

                    		format_left "{mode}#[bg=#d5c4a1,fg=#665c54] {session} "
                    		format_center "{tabs}"
                    		format_right "{pipe_zjstatus_hints}"

                    		format_space ""
                        pipe_zjstatus_hints_format "{output}"

                  		  mode_normal "${modeTemplate "NOR" "#b8bb26"}"
                  		  mode_locked "${modeTemplate "LOC" "#665c54"}"
                  		  mode_pane "${modeTemplate "PAN" "#83a598"}"
                  		  mode_tab "${modeTemplate "TAB" "#d3869b"}"
                  		  mode_rename "${modeTemplate "REN" "#fabd2f"}"
                  		  mode_resize "${modeTemplate "RES" "#8ec07c"}"
                  		  mode_scroll "${modeTemplate "SCR" "#fe8019"}"
                  		  mode_session "${modeTemplate "SES" "#d65d0e"}"

                  		  tab_normal "#[bg=#d5c4a1,fg=#665c54] {index}:{name} "
                  		  tab_active "#[bg=#665c54,fg=#d5c4a1,bold] {index}:{name}* "
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
                      pane focus=true size="72%"
                      pane size="28%"
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

            "zellij/layouts/3t2b.kdl".text = # kdl
              ''
                layout {
                  pane size="75%" split_direction="vertical" {
                      pane focus=true size="33%"
                      pane size="34%"
                      pane size="33%"
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
