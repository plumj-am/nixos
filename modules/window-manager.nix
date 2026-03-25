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
        pkgs.polkit_gnome
        pkgs.xwayland-satellite
        pkgs.xdg-utils

        (mkDesktopEntry {
          name = "Screenshot";
          exec = "niri msg action screenshot";
        })
        (mkDesktopEntry {
          name = "Screenshot-Window";
          exec = "niri msg action screenshot-window --write-to-disk";
        })
      ];

      hjem.extraModules = singleton (
        { config, ... }:
        {
          packages = singleton inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri;

          xdg.config.files."niri/config.kdl".text =
            with theme; # kdl
            ''
              window-rule {
                match app-id=r#"^*$"#
                opacity 1.0
                draw-border-with-background false
                clip-to-geometry true
                geometry-corner-radius 0
                shadow {
                  off
                }
                focus-ring {
                  off
                }
              }

              window-rule {
                match app-id=r#"^(zen-.*|org\.qutebrowser\.qutebrowser|brave-browser)$"#
                open-maximized true
                open-on-workspace "browser"
              }

              window-rule {
                match app-id=r#"^dev.zed.Zed|OpenCode$"#
                exclude title=r#"^docpad-*$"#
                open-maximized false
                open-on-workspace "editor1"
              }

              window-rule {
                match app-id=r#"^dev.zed.Zed$"#
                match title=r#"^docpad-*$"#
                open-maximized false
                open-on-workspace "editor2"
              }

              window-rule {
                match app-id=r#"^vesktop|wasistlos$"#
                open-maximized true
                open-on-workspace "chat"
              }

              window-rule {
                match app-id=r#"^thunderbird$"#
                open-maximized true
                open-on-workspace "email"
              }

              window-rule {
                match app-id=r#"^radicle-desktop|com.saivert.pwvucontrol|thunar$"#
                open-maximized true
                open-on-workspace "guis"
              }

              window-rule {
                match title=r#"^.*YouTube|Picture-in-Picture.*"#
                opacity 1.0
              }

              window-rule {
                match app-id=r#"kitty"#
              }

              window-rule {
                match app-id=r#"^zed_float$"#
                open-floating true
                default-column-width { proportion 0.66; }
                default-window-height { proportion 0.9; }
              }

              window-rule {
                match app-id=r#"^steam$"#
                open-maximized true
                open-on-workspace "games"
              }

              window-rule {
                match app-id=r#"^steam_app_*"#
                opacity 1.0
                open-on-workspace "games"
                border {
                  off
                }
                geometry-corner-radius 0
                clip-to-geometry false
              }

              layer-rule {
                match namespace=r#"notifications|launcher"#
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

              output "ASUSTek COMPUTER INC VG259QM M1LMQS084030" {
                mode "1920x1080@279.857"
                position x=0 y=0
              }

              output "PNP(BNQ) BenQ xl2411t PAD00133SL0" {
                mode "1920x1080@60.000"
                position x=1920 y=0
              }

              // output "Dell Inc. DELL U3415W F1T1W92E116L" {
              //   mode "3440x1440@49.987" // On Windows I could get 80hz but not here for some reason...
              //   position x=1920 y=0
              // }

              workspace "games" {
                open-on-output "DP-2"
              }

              workspace "guis" {
                open-on-output "DP-2"
              }

              workspace "browser" {
                open-on-output "DP-2"
              }

              workspace "chat" {
                open-on-output "DP-2"
              }

              workspace "email" {
                open-on-output "DP-2"
              }

              workspace "editor1" {
                open-on-output "DP-1"
              }
              workspace "editor2" {
                open-on-output "DP-1"
              }

              layout {
                always-center-single-column true
                empty-workspace-above-first false
                gaps 0
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
                  width ${toString border.small}
                  active-gradient from="${colors.base0B}" to="${colors.base09}" angle=45
                  inactive-color "#${colors.base01}"
                  urgent-color "#${colors.base08}"
                }
                shadow {
                  off
                  color "#${toString colors.base09}DD"
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

              screenshot-path "${config.directory}/Pictures/Screenshots/screenshot_%Y-%m-%d_%H-%M-%S.png"

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

                // Ctrl+Backspace { spawn-sh "tofi-drun | xargs niri msg action spawn --"; }
                Ctrl+Backspace { spawn-sh "qs ipc -p /home/jam/nixos/modules/quickshell/shell call launcher toggle"; }
                Mod+Shift+P { spawn "power-menu"; }
                Mod+T { spawn "process-monitor"; }
                Mod+P { spawn "process-killer"; }
                Mod+D { spawn "todo-scratchpad"; }
                Mod+S { spawn "random-scratchpad"; }
                // Mod+C { spawn-sh "cliphist list | tofi --prompt-text '[cliphist]' | cliphist decode | wl-copy"; }
                Mod+N { spawn-sh "niri msg action do-screen-transition --delay-ms 100 && notify-send hidden_toggle && makoctl mode -t mute && makoctl mode -t do-not-disturb"; }
                Mod+M { spawn-sh "niri msg action do-screen-transition --delay-ms 100 && makoctl mode -t mute && notify-send mute_toggle"; }
              }

              spawn-at-startup "quickshell --path /home/jam/nixos/modules/quickshell/shell"
              spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
              spawn-at-startup "swww-daemon"
              spawn-at-startup "gammastep-indicator"
              // spawn-at-startup "mako" // Started by NixOS.
            '';
        }
      );
    };

  # TODO: MacOS scrolling window manager?
  wmBase = { };

in
{
  flake.modules.nixos.window-manager = niriBase;
  flake.modules.darwin.window-manager = wmBase;
}
