{ pkgs, lib, config, niri, ... }: let
  inherit (lib) mkIf enabled disabled genAttrs const merge;
  myConfig = config;
in mkIf config.isDesktopNotWsl {

  environment.shellAliases.start = "niri-session";

  environment.systemPackages = [ pkgs.xwayland-satellite ];

  home-manager.sharedModules = [
    niri.homeModules.niri ({ config, ... }: let
        niriConfig = config;
      in {
    programs.niri = enabled {
      package = niri.packages.${pkgs.system}.niri-unstable;
      settings = {

        window-rules = [
          {
            matches = [{ app-id = "^*$"; }];

            opacity                     = 0.97;
            draw-border-with-background = false;
            clip-to-geometry            = true;
            geometry-corner-radius      = genAttrs
                [ "top-left" "top-right" "bottom-left" "bottom-right" ]
                (const (myConfig.theme.radius * 1.5 + 0.0)); # Convert to floating point.
          }
          {
            matches = [{ app-id = "^zen-.*$"; }];

            opacity = 0.98;
          }
          {
            matches = [{ title = "^.*YouTube.*"; }];

            opacity = 1.0;
          }
          {
            matches = [{ app-id = "^fuzzel$"; }];

            # ...
          }
          {
            matches = [{ app-id = "kitty"; }];

            # ...
          }
          # Game optimisations.
          {
            matches = [{ app-id = "^steam_app_*"; }];

            opacity                = 1.0;
            open-fullscreen        = true;
            border                 = disabled;
            focus-ring             = disabled;
            shadow                 = disabled;
            geometry-corner-radius = null;
            clip-to-geometry       = false;
          }
        ];

        layer-rules = [
          {
            matches = [{ namespace = "waybar"; }];
            opacity = 0.9;
          }
        ];

        spawn-at-startup = [
          { argv = [ "waybar" ]; }
          { argv = [ "swww-daemon" ]; }
          { argv = [ "mako" ]; }
        ];

        input = merge {
          focus-follows-mouse = enabled;
          power-key-handling  = disabled;
        } <| genAttrs [ "mouse" "touchpad" "trackball" "trackpoint" ] (const {
          left-handed    = true;
          accel-profile  = "flat";
          natural-scroll = false;
        });

        hotkey-overlay.hide-not-bound = true;

        gestures.hot-corners = disabled;

        layout = {

          preset-column-widths = [
            { proportion = 1. / 3.; }
            { proportion = 1. / 2.; }
            { proportion = 2. / 3.; }
            { proportion = 3. / 4.; }
          ];

          preset-window-heights = [
            { proportion = 1. / 2.; }
            { proportion = 2. / 3.; }
            { proportion = 1.; }
          ];

          gaps = myConfig.theme.margin;

          # center-focused-column = "on-overflow";

          border = enabled {
            width = myConfig.theme.border * 1.5;
            active = {
              gradient = {
                relative-to = "workspace-view";
                angle = 45;
                from  = "#${myConfig.theme.colors.base0B}";
                to    = "#${myConfig.theme.colors.base09}";
              };
            };
            inactive.color = "#${myConfig.theme.colors.base00}";
            urgent.color   = "#${myConfig.theme.colors.base08}";
          };

          shadow = enabled {
            color              = "#${toString myConfig.theme.colors.base00}DD";
            draw-behind-window = false;
            softness           = 30;
            spread             = 5;
          };

          focus-ring = disabled;
        };

        binds = with niriConfig.lib.niri.actions;  let
          nu = spawn "nu" "-c";
        in {

          "Mod+slash".action       = show-hotkey-overlay;
          "Mod+Shift+slash".action = show-hotkey-overlay;

          "Mod+Q" = { action = close-window; repeat = false; };
          "Mod+Tab".action   = toggle-overview;

          "Mod+1".action = focus-workspace 1;
          "Mod+2".action = focus-workspace 2;
          "Mod+3".action = focus-workspace 3;
          "Mod+4".action = focus-workspace 4;
          "Mod+5".action = focus-workspace 5;
          "Mod+6".action = focus-workspace 6;
          "Mod+7".action = focus-workspace 7;
          "Mod+8".action = focus-workspace 8;

          "Mod+F".action            = maximize-column;
          "Mod+Shift+T".action      = toggle-window-floating;
          "Mod+Shift+Ctrl+T".action = switch-focus-between-floating-and-tiling;
          "Mod+R".action            = switch-preset-window-width;
          "Mod+Shift+R".action      = switch-preset-window-height;
          "Mod+Minus".action        = set-column-width "-10%";
          "Mod+Equal".action        = set-column-width "+10%";

          "Mod+H".action = focus-column-or-monitor-left;
          "Mod+L".action = focus-column-or-monitor-right;

          "Mod+Shift+H".action = move-column-left-or-to-monitor-left;
          "Mod+Shift+L".action = move-column-right-or-to-monitor-right;

          "Mod+J".action = focus-workspace-down;
          "Mod+K".action = focus-workspace-up;

          "Mod+Shift+J".action = move-window-down-or-to-workspace-down;
          "Mod+Shift+K".action = move-window-up-or-to-workspace-up;

          "Ctrl+Backspace".action = spawn "fuzzel";
          "Mod+Shift+P".action    = spawn "power-menu";
          "Mod+T".action          = spawn "process-monitor";
          "Mod+P".action          = spawn "process-killer";
          "Mod+D".action          = spawn "todo-scratchpad";
          "Mod+S".action          = spawn "random-scratchpad";
          "Mod+V".action          = nu ''cliphist list | fuzzel --dmenu | cliphist decode | wl-copy'';
          "Mod+C".action          = nu ''cliphist list | fuzzel --dmenu | cliphist decode | wl-copy'';
        };

        cursor.hide-when-typing = true;

        animations.slowdown = 2.75;


      };
    };
  })];
}
