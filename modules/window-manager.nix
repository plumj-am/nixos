let
  niriBase =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) theme;
      inherit (config.myLib) mkDesktopEntry;
    in
    {
      xdg.portal = {
        enable = true;
        config = {
          common.default = "*";
          # [1/2] Niri screensharing fixes.
          niri.default = "*";
          niri."org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        };

        extraPortals = [
          # [2/2] Niri screensharing fixes.
          pkgs.xdg-desktop-portal-gnome
        ];
      };

      environment.sessionVariables = {
        # Hint Electron apps to use Wayland.
        NIXOS_OZONE_WL = "1";
        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "niri";
      };

      environment.systemPackages = [
        pkgs.cliphist
        pkgs.xwayland-satellite
        pkgs.xdg-utils
        inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable

        (mkDesktopEntry { inherit pkgs; } {
          name = "Screenshot";
          exec = "niri msg action screenshot";
        })
        (mkDesktopEntry { inherit pkgs; } {
          name = "Screenshot-Window";
          exec = "niri msg action screenshot-window --write-to-disk";
        })
      ];

      hjem.extraModules = singleton {
        packages = singleton inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;

        xdg.config.files."niri/config.kdl".text =
          with theme; # kdl
          ''
                window-rule {
                  match app-id=r#"^*$"#
                  opacity 1.0
                  draw-border-with-background false
                  clip-to-geometry true
                  geometry-corner-radius ${toString (theme.radius.tiny * 1.0)}
                  shadow {
                    off
                  }
                  focus-ring {
                    off
                  }
                }

                window-rule {
                  match app-id=r#"^(zen-.*|org\.qutebrowser\.qutebrowser|brave-browser)$"#
                  opacity 1.0
                  open-maximized true
                }

                window-rule {
                  match title=r#"^.*YouTube|Picture-in-Picture.*"#
                  opacity 1.0
                }

                window-rule {
                  match app-id=r#"kitty"#
                }

                window-rule {
                  match app-id=r#"^steam_app_*"#
                  opacity 1.0
                  open-fullscreen true
                  border {
                    off
                  }
                  geometry-corner-radius 0
                  clip-to-geometry false
                }

                layer-rule {
                  match namespace=r#"ashell|notifications|launcher"#
                  opacity 1.0
                }

                input {
                  focus-follows-mouse
                  warp-mouse-to-focus
                  disable-power-key-handling

                  mouse {
                    accel-profile "flat"
                    left-handed
                  }

                  touchpad {
                    accel-profile "flat"
                    left-handed
                  }

                  trackball {
                    accel-profile "flat"
                    left-handed
                  }

                  trackpoint {
                    accel-profile "flat"
                    left-handed
                  }
                }

                layout {
                  always-center-single-column true
                  empty-workspace-above-first true
                  gaps ${toString theme.margin.small}
                  preset-column-widths {
                    proportion 0.20
                    proportion 0.25
                    proportion 0.33
                    proportion 0.50
                    proportion 0.66
                    proportion 0.75
                    proportion 0.80
                  }
                  preset-window-heights {
                    proportion 0.50
                    proportion 0.66
                    proportion 1.00
                  }

                  border {
                    on
                    width ${toString theme.border.normal}
                    active-gradient from="${theme.colors.base0B}" to="${theme.colors.base09}" angle=45
                    inactive-color "#${theme.colors.base00}"
                    urgent-color "#${theme.colors.base08}"
                  }
                  shadow {
                    off
                    color "#${toString theme.colors.base09}DD"
                    draw-behind-window false
                    softness 10
                    offset x=0 y=0
                  }
                  focus-ring {
                    off
                  }
                }

                animations {
                  slowdown 0.75
                }

                //   window-open {
                //     curve "ease-out-cubic"
                //     duration-ms 150
                //   }

                //   window-close {
                //     curve "ease-out-expo"
                //     duration-ms 150
                //   }

                //   window-movement {
                //     spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
                //   }

                //   window-resize {
                //     spring damping-ratio=1.0 stiffness=1200 epsilon=0.0001
                //   }
                // }

                cursor {
                  hide-when-typing
                }

                hotkey-overlay {
                  skip-at-startup
                }

                gestures {
                  hot-corners {
                    off
                  }
                }

                screenshot-path "/home/jam/Pictures/Screenshots/screenshot_%Y-%m-%d_%H-%M-%S.png"

            binds {
              Mod+slash { show-hotkey-overlay; }
              Mod+Shift+slash { show-hotkey-overlay; }

              Mod+Q repeat=false { close-window; }
              Mod+Tab repeat=false { toggle-overview; }

              Mod+1 { focus-workspace 1; }
              Mod+2 { focus-workspace 2; }
              Mod+3 { focus-workspace 3; }
              Mod+4 { focus-workspace 4; }
              Mod+5 { focus-workspace 5; }
              Mod+6 { focus-workspace 6; }
              Mod+7 { focus-workspace 7; }
              Mod+8 { focus-workspace 8; }

              Mod+Ctrl+H { focus-monitor-left; }
              Mod+Ctrl+L { focus-monitor-right; }

              Mod+F { expand-column-to-available-width; }
              Mod+Shift+F { maximize-column; }
              Mod+Shift+C { center-visible-columns; }
              Mod+Shift+T { toggle-window-floating; }
              Mod+Shift+Ctrl+T { switch-focus-between-floating-and-tiling; }
              Mod+W { toggle-column-tabbed-display; }
              Mod+R { switch-preset-window-width; }
              Mod+Shift+R { switch-preset-window-height; }

              Mod+Minus { set-column-width "-10%"; }
              Mod+Equal { set-column-width "+10%"; }
              Mod+Shift+Minus { set-window-height "-10%"; }
              Mod+Shift+Equal { set-window-height "+10%"; }

              Mod+H { focus-column-or-monitor-left; }
              Mod+L { focus-column-or-monitor-right; }
              Mod+J { focus-workspace-down; }
              Mod+K { focus-workspace-up; }

              Mod+Shift+H { move-column-left-or-to-monitor-left; }
              Mod+Shift+L { move-column-right-or-to-monitor-right; }
              Mod+Shift+J { move-window-down-or-to-workspace-down; }
              Mod+Shift+K { move-window-up-or-to-workspace-up; }

              Mod+Comma { consume-window-into-column; }
              Mod+Period { expel-window-from-column; }
              Mod+Shift+Comma { consume-or-expel-window-left; }
              Mod+Shift+Period { consume-or-expel-window-right; }

              Ctrl+Backspace { spawn-sh "tofi-drun | xargs niri msg action spawn --"; }
              Mod+Shift+P { spawn "power-menu"; }
              Mod+T { spawn "process-monitor"; }
              Mod+P { spawn "process-killer"; }
              Mod+D { spawn "todo-scratchpad"; }
              Mod+S { spawn "random-scratchpad"; }
              Mod+C { spawn-sh "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"; }
              // TODO: Adapt for ashell.
              // Mod+B { spawn-sh "niri msg action do-screen-transition --delay-ms 100 && notify-send bar_toggle && pkill -USR1 waybar"; }
              Mod+N { spawn-sh "niri msg action do-screen-transition --delay-ms 100 && notify-send hidden_toggle && makoctl mode -t mute && makoctl mode -t do-not-disturb"; }
              Mod+M { spawn-sh "niri msg action do-screen-transition --delay-ms 100 && makoctl mode -t mute && notify-send mute_toggle"; }
              // TODO: Adapt for ashell.
              // Mod+Z { spawn-sh "niri msg action do-screen-transition --delay-ms 100 && notify-send zen_toggle && pkill -USR1 waybar && makoctl mode -t mute && makoctl mode -t do-not-disturb"; }
            }

            // spawn-at-startup "quickshell" // Not using yet.
            spawn-at-startup "ashell"
            spawn-at-startup "swww-daemon"
            // spawn-at-startup "mako" // Started by NixOS.
          '';
      };

    };

  # TODO: MacOS scrolling window manager?
  wmBase = { };

in
{
  flake-file.inputs = {
    niri = {
      url = "github:sodiboo/niri-flake";

      inputs.nixpkgs.follows = "os";
    };
  };

  flake.modules.nixos.window-manager = niriBase;
  flake.modules.darwin.window-manager = wmBase;
}
