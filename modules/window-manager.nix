{
  config.flake.modules.hjem.window-manager =
    {
      inputs,
      pkgs,
      config,
      theme,
      ...
    }:
    let
      cfg = config // {
        inherit theme;
      };
    in
    {
      rum.programs.nushell.aliases.ns = "niri-session";

      rum.desktops.niri = {
        enable = true;
        package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;

        config = ''
          window-rule {
            match app-id=r#"^*$"#
            opacity ${toString cfg.theme.opacity.opaque}
            draw-border-with-background false
            clip-to-geometry true
            geometry-corner-radius ${toString (cfg.theme.radius.small * 1.0)}
          }

          window-rule {
            match app-id=r#"^(zen-.*|org\.qutebrowser\.qutebrowser|brave-browser)$"#
            opacity ${toString cfg.theme.opacity.opaque}
          }

          window-rule {
            match title=r#"^.*YouTube|Picture-in-Picture.*"#
            opacity ${toString cfg.theme.opacity.opaque}
          }

          window-rule {
            match app-id=r#"kitty"#
          }

          window-rule {
            match app-id=r#"^steam_app_*"#
            opacity ${toString cfg.theme.opacity.opaque}
            open-fullscreen true
            border {
              off
            }
            focus-ring {
              off
            }
            shadow {
              off
            }
            geometry-corner-radius 0
            clip-to-geometry false
          }

          layer-rule {
            match namespace=r#"waybar|notifications|launcher"#
            shadow {
              off
              color "#${toString cfg.theme.colors.base09}33"
              draw-behind-window true
              softness 15
              offset x=0 y=0
            }
          }

          layer-rule {
            match namespace=r#"waybar"#
            opacity ${toString cfg.theme.opacity.opaque}
          }

          layer-rule {
            match namespace=r#"notifications|launcher"#
            opacity ${toString cfg.theme.opacity.opaque}
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
            gaps ${toString cfg.theme.margin.small}
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
              width ${toString cfg.theme.border.normal}
              active-gradient from="${cfg.theme.colors.base0B}" to="${cfg.theme.colors.base09}" angle=45
              inactive-color "#${cfg.theme.colors.base00}"
              urgent-color "#${cfg.theme.colors.base08}"
            }
            shadow {
              off
              color "#${toString cfg.theme.colors.base09}DD"
              draw-behind-window false
              softness 10
              offset x=0 y=0
            }
            focus-ring {
              off
            }
          }

          // animations {
          //   slowdown 2.25

          //   window-open {
          //     curve "ease-out-cubic"
          //     duration-ms ${toString cfg.theme.duration.ms.normal}
          //   }

          //   window-close {
          //     curve "ease-out-expo"
          //     duration-ms ${toString cfg.theme.duration.ms.short}
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
        '';

        binds = {
          "Mod+slash".action = "show-hotkey-overlay";
          "Mod+Shift+slash".action = "show-hotkey-overlay";

          "Mod+Q" = {
            action = "close-window";
            parameters.repeat = false;
          };
          "Mod+Tab" = {
            action = "toggle-overview";
            parameters.repeat = false;
          };

          "Mod+1".action = "focus-workspace 1";
          "Mod+2".action = "focus-workspace 2";
          "Mod+3".action = "focus-workspace 3";
          "Mod+4".action = "focus-workspace 4";
          "Mod+5".action = "focus-workspace 5";
          "Mod+6".action = "focus-workspace 6";
          "Mod+7".action = "focus-workspace 7";
          "Mod+8".action = "focus-workspace 8";

          "Mod+Ctrl+H".action = "focus-monitor-left";
          "Mod+Ctrl+L".action = "focus-monitor-right";

          "Mod+F".action = "expand-column-to-available-width";
          "Mod+Shift+F".action = "maximize-column";
          "Mod+Shift+C".action = "center-visible-columns";
          "Mod+Shift+T".action = "toggle-window-floating";
          "Mod+Shift+Ctrl+T".action = "switch-focus-between-floating-and-tiling";
          "Mod+W".action = "toggle-column-tabbed-display";
          "Mod+R".action = "switch-preset-window-width";
          "Mod+Shift+R".action = "switch-preset-window-height";

          "Mod+Minus".action = "set-column-width \"-10%\"";
          "Mod+Equal".action = "set-column-width \"+10%\"";
          "Mod+Shift+Minus".action = "set-window-height \"-10%\"";
          "Mod+Shift+Equal".action = "set-window-height \"+10%\"";

          "Mod+H".action = "focus-column-or-monitor-left";
          "Mod+L".action = "focus-column-or-monitor-right";
          "Mod+J".action = "focus-workspace-down";
          "Mod+K".action = "focus-workspace-up";

          "Mod+Shift+H".action = "move-column-left-or-to-monitor-left";
          "Mod+Shift+L".action = "move-column-right-or-to-monitor-right";
          "Mod+Shift+J".action = "move-window-down-or-to-workspace-down";
          "Mod+Shift+K".action = "move-window-up-or-to-workspace-up";

          "Mod+Comma".action = "consume-window-into-column";
          "Mod+Period".action = "expel-window-from-column";
          "Mod+Shift+Comma".action = "consume-or-expel-window-left";
          "Mod+Shift+Period".action = "consume-or-expel-window-right";

          "Ctrl+Backspace".spawn = [ "fuzzel" ];
          "Mod+Shift+P".spawn = [ "power-menu" ];
          "Mod+T".spawn = [ "process-monitor" ];
          "Mod+P".spawn = [ "process-killer" ];
          "Mod+D".spawn = [ "todo-scratchpad" ];
          "Mod+S".spawn = [ "random-scratchpad" ];
          "Mod+C".spawn = [ "nu -c cliphist list | fuzzel --dmenu | cliphist decode | wl-copy" ];
        };

        spawn-at-startup = [
          # [ "waybar" ] # Started by NixOS.
          [ "swww-daemon" ]
          [ "mako" ]
        ];
      };

    };
  config.flake.modules.nixos.window-manager =
    { inputs, pkgs, ... }:
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
        pkgs.xwayland-satellite
        inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable

        (pkgs.writeTextFile {
          name = "screenshot";
          destination = "/share/applications/screenshot.desktop";
          text = ''
            [Desktop Entry]
            Name=Screenshot
            Icon=camera-web
            Exec=niri msg action screenshot
            Terminal=false
          '';
        })

        (pkgs.writeTextFile {
          name = "screenshot-window";
          destination = "/share/applications/screenshot-window.desktop";
          text = ''
            [Desktop Entry]
            Name=Screenshot Window
            Icon=camera-web
            Exec=niri msg action screenshot-window --write-to-disk
            Terminal=false
          '';
        })
      ];
    };

  # TODO: MacOS scrolling window manager?
  config.flake.modules.darwin.window-manager = { };
}
