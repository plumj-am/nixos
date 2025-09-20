{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktopNotWsl {
  hardware.graphics = enabled;

  xdg.portal = enabled {
    config.common.default = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    configPackages = [ pkgs.hyprland ];
  };

  programs.xwayland = enabled;

  environment.systemPackages = [
    pkgs.hyprland
  ];

  home-manager.sharedModules = [{
    wayland.windowManager.hyprland = enabled {
      settings = {
        # Monitor configuration - auto-detect setup
        monitor = [
          # Primary monitor configs for different setups
          "DP-1,3840x1440@80,0x0,1"        # 4K main if available
          "DP-2,1920x1080@280,3840x0,1"    # 1080p secondary if available
          ",1920x1080@144,auto,1"          # Fallback for single monitor
        ];

        bind = [
          # Config and window controls
          "SUPER, O, exec, hyprctl reload"
          "SUPER, Q, killactive"
          "SUPER, M, exec, hyprctl dispatch movetoworkspace special"

          # Focus windows
          "SUPER, H, movefocus, l"
          "SUPER, J, movefocus, d"
          "SUPER, K, movefocus, u"
          "SUPER, L, movefocus, r"

          # Move windows
          "SUPER SHIFT, H, movewindow, l"
          "SUPER SHIFT, J, movewindow, d"
          "SUPER SHIFT, K, movewindow, u"
          "SUPER SHIFT, L, movewindow, r"
          "SUPER SHIFT, Return, layoutmsg, swapwithmaster"

          # Window toggles
          "SUPER, T, togglefloating"
          "SUPER SHIFT, F, fullscreen, 1"

          # Workspaces
          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"
          "SUPER, 6, workspace, 6"
          "SUPER, 7, workspace, 7"
          "SUPER, 8, workspace, 8"

          # Move windows to workspaces
          "SUPER SHIFT, 1, movetoworkspace, 1"
          "SUPER SHIFT, 2, movetoworkspace, 2"
          "SUPER SHIFT, 3, movetoworkspace, 3"
          "SUPER SHIFT, 4, movetoworkspace, 4"
          "SUPER SHIFT, 5, movetoworkspace, 5"
          "SUPER SHIFT, 6, movetoworkspace, 6"
          "SUPER SHIFT, 7, movetoworkspace, 7"
          "SUPER SHIFT, 8, movetoworkspace, 8"

          # Launcher
          "CTRL, BackSpace, exec, fuzzel"
        ];

        # Resize controls
        binde = [
          "SUPER, equal, resizeactive, 50 0"
          "SUPER, minus, resizeactive, -50 0"
          "SUPER SHIFT, equal, resizeactive, 0 50"
          "SUPER SHIFT, minus, resizeactive, 0 -50"
        ];

        # Auto-start waybar
        exec-once = [
          "waybar"
        ];

        # Basic appearance
        general = with config.theme.with0x; {
          gaps_in = 0;
          gaps_out = 0;
          border_size = config.theme.borderWidth;
          "col.active_border" = "0xFF${config.theme.colors.base0D}";
          "col.inactive_border" = "0xFF${config.theme.colors.base02}";
        };

        decoration = {
          rounding = config.theme.cornerRadius;
        };

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = false;
          };
        };
      };
    };
  }];
}