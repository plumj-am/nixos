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
    pkgs.wl-clipboard
    pkgs.xdg-utils
  ];

  home-manager.sharedModules = [{
    wayland.windowManager.hyprland = enabled {
      systemd = enabled {
        enableXdgAutostart = true;
      };
      settings = {
        monitor = if config.networking.hostName == "yuzu" then [
          # Yuzu: 1920*1080@280hz left, 3840*1440@50hz right.
          "DP-1,1920x1080@280,0x0,1"   # Main (front).
          "DP-2,3440x1440@50,1920x0,1" # Secondary (right).
        ] else [
          # Date: 1920*1080@144hz
          ",1920x1080@144,auto,1"
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
          gaps_in     = 0;
          gaps_out    = 0;
          border_size = config.theme.borderWidth;

          "col.active_border"   = "0xFF${config.theme.colors.base0D}";
          "col.inactive_border" = "0xFF${config.theme.colors.base02}";
        };

        decoration = {
          rounding     = config.theme.cornerRadius;
          blur.enabled = false;
        };

        cursor = {
          hide_on_key_press = true;
          inactive_timeout  = 10;
          no_warps          = true;
        };

        input = {
          kb_layout    = "us";
          follow_mouse = 0;
          left_handed  = true;
          touchpad = {
            natural_scroll = false;
          };
        };
      };
    };
  }];
}
