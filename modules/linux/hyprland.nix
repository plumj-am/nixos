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

  # Hint Electron apps to use wayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager.sharedModules = [{
    wayland.windowManager.hyprland = enabled {
      systemd = enabled {
        enableXdgAutostart = true;
      };
      settings = {
        monitor = if config.networking.hostName == "yuzu" then [
          # Yuzu: 1920*1080@280hz left, 3840*1440@50hz right.
          ",preferred,auto,1"   # Main (front).
          ",preferred,auto,1"   # Secondary (right).
        ] else [
          # Date: 1920*1080@144hz
          ",preferred,auto,1"
        ];

        bind = [
          # Config and window controls
          "SUPER, O, exec, hyprctl reload"
          "SUPER, Q, killactive"
          "SUPER, M, exec, hyprctl dispatch movetoworkspace special"
          "SUPER SHIFT, M, togglespecialworkspace"

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
          "SUPER, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"
          "SUPER, P, exec, power-menu"
          "SUPER SHIFT, P, exec, process-killer"
          "SUPER, W, exec, window-switcher"
          "SUPER, G, togglespecialworkspace, games"
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
        general = with config.theme; {
          gaps_in     = margin / 4;
          gaps_out    = margin / 2;
          border_size = border;

          "col.active_border"   = "0xFF${config.theme.colors.base0D}";
          "col.inactive_border" = "0xFF${config.theme.colors.base02}";
        };

        decoration = {
          rounding     = config.theme.radius;
          blur.enabled = false;
        };

        cursor = {
          hide_on_key_press = true;
          inactive_timeout  = 10;
          no_warps          = true;
        };

        dwindle = {
          preserve_split = true;
          smart_resizing = false;
        };

        animations = {
          bezier = [ "material_decelerate, 0.05, 0.7, 0.1, 1" ];

          animation = [
            "border    , 1, 3, material_decelerate"
            "fade      , 1, 3, material_decelerate"
            "layers    , 1, 3, material_decelerate"
            "windows   , 1, 3, material_decelerate, popin 80%"
            "workspaces, 1, 3, material_decelerate"
          ];
        };

        misc = {
          animate_manual_resizes   = true;
          background_color         = config.theme.with0x.base00;
          disable_hyprland_logo    = true;
          disable_splash_rendering = true;

          # Wakes screen.
          key_press_enables_dpms   = true;
          mouse_move_enables_dpms  = true;
        };

        # Game window rules - Steam games only
        windowrulev2 = [
          "workspace special:games, class:^(steam_app_).*"
          "fullscreen, class:^(steam_app_).*"
          "immediate, class:^(steam_app_).*"    # Reduce input lag.
          "noborder, class:^(steam_app_).*"     # Remove borders for fullscreen.
          "noanim, class:^(steam_app_).*"       # Disable animations for performance.
          "noblur, class:^(steam_app_).*"       # Disable blur for performance.
          "noshadow, class:^(steam_app_).*"     # Disable shadows for performance.
        ];

        input = {
          kb_layout     = "us";
          follow_mouse  = 1;
          left_handed   = true;

          # Disable mouse acceleration
          accel_profile = "flat";
          sensitivity   = 0;

          touchpad.natural_scroll = false;
        };
      };
    };
  }];
}
