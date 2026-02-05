{
  flake.modules.nixos.waybar = {
    programs.waybar.enable = true;
  };

  flake.modules.hjem.waybar =
    {
      pkgs,
      lib,
      theme,
      isDesktop,
      isLinux,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.meta) getExe getExe';
      inherit (builtins) concatStringsSep map toString;

      nu = "${getExe pkgs.nushell} -c";
      bash = "${getExe pkgs.bash} -c";
      kitty = "${getExe pkgs.kitty} --hold";
      btop = getExe pkgs.btop;

      enable = true;
    in
    mkIf (isDesktop && isLinux && enable) {
      xdg.config.files."waybar/config.jsonc".text =
        # jsonc
        ''
          {
            "layer": "top",
            "height": 32,
            "margin-top": ${toString theme.margin.small},
            "margin-left": ${toString theme.margin.small},
            "margin-right": ${toString theme.margin.small},
            "margin-bottom": 0,

            "modules-left": ["niri/workspaces"],
            "modules-center": ["niri/window"],
            "modules-right": [
              "tray",
              "pulseaudio",
              "cpu",
              "memory",
              "disk",
              "custom/gpu",
              "battery",
              "clock"
            ],

            "niri/workspaces": {
              "current-only": true,
              "format": "{index}"
            },

            "niri/window": {
              "max-length": 50,
              "separate-outputs": true,
              "rewrite": {
                "(.*) (—|-) (Zen Browser|Brave)": "󰖟  $1",
                "(.*) - Discord": "󰙯  $1",
                "(.*) — nu": " $1"
              }
            },

            "tray": {
              "reverse-direction": true,
              "spacing": 5
            },

            "pulseaudio": {
              "format": "{format_source} {icon}  {volume}%",
              "format-muted": "{format_source}  󰸈",
              "format-source": "󰍬",
              "format-source-muted": "",
              "format-icons": {
                "default": ["󰕿", "󰖀", "󰕾"]
              },
              "on-click": "${getExe pkgs.pwvucontrol}",
              "on-click-right": "${getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle",
              "tooltip": true,
              "tooltip-format": "Volume: {volume}%"
            },

            "cpu": {
              "format": "󰘚  {usage}%",
              "tooltip": true,
              "tooltip-format": "CPU Usage: {usage}%\nLoad: {load}",
              "interval": 3,
              "on-click": "${kitty} ${nu} '${btop}'",
              "states": {
                "warning": 70,
                "critical": 90
              }
            },

            "memory": {
              "format": "󰽘  {used:0.1f}G/{total:0.1f}G",
              "tooltip": true,
              "tooltip-format": "Memory: {used:0.1f}G/{total:0.1f}G ({percentage}%)\nAvailable: {avail:0.1f}G",
              "interval": 3,
              "on-click": "${kitty} ${nu} '${btop}'",
              "states": {
                "warning": 70,
                "critical": 90
              }
            },

            "disk": {
              "format": "󰋊  {percentage_used}%",
              "path": "/",
              "tooltip": true,
              "tooltip-format": "Disk: {used}/{total} ({percentage_used}%)\nAvailable: {free}",
              "interval": 600,
              "states": {
                "warning": 70,
                "critical": 90
              }
            },

            "custom/gpu": {
              "exec": "${bash} 'if command -v nvidia-smi >/dev/null; then nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1; elif command -v radeontop >/dev/null; then radeontop -d - -l 1 | grep -o \"gpu [0-9]*\" | cut -d\" \" -f2; else echo \"N/A\"; fi'",
              "format": "󰢮  {}%",
              "interval": 5,
              "tooltip": true,
              "tooltip-format": "GPU Usage: {}%",
              "on-click": "${kitty} ${nu} '${btop}'",
              "states": {
                "warning": 70,
                "critical": 90
              }
            },

            "battery": {
              "format": "{icon}  {capacity}%",
              "format-charging": "󰂄  {capacity}%",
              "format-plugged": "󰂄  {capacity}%",
              "format-icons": [
                "󰁺", "󰁻", "󰁼", "󰁽", "󰁾",
                "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"
              ],
              "tooltip": true,
              "tooltip-format": "Battery: {capacity}%\nTime: {time}\nHealth: {health}%",
              "states": {
                "warning": 30,
                "critical": 15
              }
            },

            "clock": {
              "interval": 1,
              "format": " {:%Y-%m-%d | %H:%M:%S}",
              "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
            }
          }
        '';

      xdg.config.files."waybar/style.css".text =
        with theme.withHash; # css
        ''
          * {
            border: none;
            border-radius: 0;
            font-family: "${theme.font.sans.name}";
            font-size: ${toString theme.font.size.normal}px;
            margin: 0;
            padding: 0;
          }

          #waybar {
            background: rgba(${concatStringsSep ", " (map toString theme.withRgb.base00)}, 1.0);
            color: ${base07};
            border: ${toString theme.border.small}px solid transparent;
            border-radius: ${toString theme.radius.small}px;
            border-image: linear-gradient(225deg, ${base0B}, ${base09}) ${toString theme.border.small};
            border-image-slice: 1;
          }

          #window {
            color: ${base07};
          }

          #window > box {
            margin: 0;
            padding: 0;
            border: none;
          }

          #workspaces button {
            padding: 0 ${toString theme.padding.normal}px;
            border: ${toString theme.border.small}px solid transparent;
            border-radius: ${toString theme.radius.small}px;
          }

          #workspaces button.empty {
            color: ${base03};
          }

          #workspaces button.active {
            color: ${base07};
            background: rgba(${concatStringsSep ", " (map toString theme.withRgb.base00)}, 0.45) padding-box;
          }

          #tray, #pulseaudio, #cpu, #memory, #disk, #battery, #clock, #custom-gpu {
            margin: 0;
            margin-left: ${toString theme.margin.normal}px;
            padding: 0 ${toString theme.padding.normal}px;
            color: ${base07}; /* Use highest contrast text */
          }

          #clock {
            min-width: 125px;
          }

          #cpu, #memory, #disk, #custom-gpu {
            min-width: 42px;
          }

          #battery.critical:not(.charging) #cpu.critical, #memory.critical, #disk.critical, #custom-gpu.critical {
            color: ${base08};
          }

          #cpu.warning, #memory.warning, #disk.warning, #custom-gpu.warning {
            color: ${base0A};
          }
        '';
    };

  flake.modules.hjem.polybar =
    {
      pkgs,
      lib,
      theme,
      isDesktop,
      isLinux,
      ...
    }:
    let
      inherit (lib.modules) mkIf;

      enable = false;
    in
    mkIf (isDesktop && isLinux && enable) {
      packages = [ pkgs.polybar ];

      xdg.config.files."polybar/config.ini".text =
        with theme; # ini
        ''
          [colors]
            background = #282A2E
            background-alt = #373B41
            foreground = #C5C8C6
            primary = #F0C674
            secondary = #8ABEB7
            alert = #A54242
            disabled = #707880

          [bar/example]
            width = 100%
            height = 24pt
            radius = ${toString radius.small}

            background = ''${colors.background}
            foreground = ''${colors.foreground}

            line-size = 3pt

            border-size = 4pt
            border-color = #00000000

            padding-left = 0
            padding-right = 1

            module-margin = 1

            separator = |
            separator-foreground = ''${colors.disabled}

            font-0 = ${font.sans.name};2

            modules-left = xworkspaces xwindow
            modules-right = filesystem pulseaudio xkeyboard memory cpu wlan eth date

            cursor-click = pointer
            cursor-scroll = ns-resize

            enable-ipc = true

            ; wm-restack = generic
            ; wm-restack = bspwm
            ; wm-restack = i3

            ; override-redirect = true

            ; This module is not active by default (to enable it, add it to one of the
            ; modules-* list above).
            ; Please note that only a single tray can exist at any time. If you launch
            ; multiple bars with this module, only a single one will show it, the others
            ; will produce a warning. Which bar gets the module is timing dependent and can
            ; be quite random.
            ; For more information, see the documentation page for this module:
            ; https://polybar.readthedocs.io/en/stable/user/modules/tray.html
          [module/systray]
            type = internal/tray

            format-margin = 8pt
            tray-spacing = 16pt

          [module/xworkspaces]
            type = internal/xworkspaces

            label-active = %name%
            label-active-background = ''${colors.background-alt}
            label-active-underline= ''${colors.primary}
            label-active-padding = 1

            label-occupied = %name%
            label-occupied-padding = 1

            label-urgent = %name%
            label-urgent-background = ''${colors.alert}
            label-urgent-padding = 1

            label-empty = %name%
            label-empty-foreground = ''${colors.disabled}
            label-empty-padding = 1

          [module/xwindow]
            type = internal/xwindow
            label = %title:0:60:...%

            [module/filesystem]
            type = internal/fs
            interval = 25

            mount-0 = /

            label-mounted = %{F#F0C674}%mountpoint%%{F-} %percentage_used%%

            label-unmounted = %mountpoint% not mounted
            label-unmounted-foreground = ''${colors.disabled}

          [module/pulseaudio]
            type = internal/pulseaudio

            format-volume-prefix = "VOL "
            format-volume-prefix-foreground = ''${colors.primary}
            format-volume = <label-volume>

            label-volume = %percentage%%

            label-muted = muted
            label-muted-foreground = ''${colors.disabled}

          [module/xkeyboard]
            type = internal/xkeyboard
            blacklist-0 = num lock

            label-layout = %layout%
            label-layout-foreground = ''${colors.primary}

            label-indicator-padding = 2
            label-indicator-margin = 1
            label-indicator-foreground = ''${colors.background}
            label-indicator-background = ''${colors.secondary}

          [module/memory]
            type = internal/memory
            interval = 2
            format-prefix = "RAM "
            format-prefix-foreground = ''${colors.primary}
            label = %percentage_used:2%%

          [module/cpu]
            type = internal/cpu
            interval = 2
            format-prefix = "CPU "
            format-prefix-foreground = ''${colors.primary}
            label = %percentage:2%%

          [network-base]
            type = internal/network
            interval = 5
            format-connected = <label-connected>
            format-disconnected = <label-disconnected>
            label-disconnected = %{F#F0C674}%ifname%%{F#707880} disconnected

          [module/wlan]
            inherit = network-base
            interface-type = wireless
            label-connected = %{F#F0C674}%ifname%%{F-} %essid% %local_ip%

          [module/eth]
            inherit = network-base
            interface-type = wired
            label-connected = %{F#F0C674}%ifname%%{F-} %local_ip%

          [module/date]
            type = internal/date
            interval = 1

            date = %H:%M
            date-alt = %Y-%m-%d %H:%M:%S

            label = %date%
            label-foreground = ''${colors.primary}

          [settings]
            screenchange-reload = true
            pseudo-transparency = true

          # [bar/plumjam]
          #   height=50
          #   width=100%
        '';
    };

  flake.modules.hjem.ashell =
    {
      pkgs,
      lib,
      isDesktop,
      isLinux,
      ...
    }:
    let
      inherit (lib.modules) mkIf;

      enable = false;
      toml = pkgs.formats.toml { };

      settings = {
        modules = {
          shutdown_cmd = "systemctl poweroff";
          suspend_cmd = "hyprlock --quiet & systemctl suspend";
          hibernate_cmd = "hyprlock --quiet & systemctl hibernate";
          reboot_cmd = "systemctl reboot";
          logout_cmd = "hyprlock --quiet --grace 60";
        };
      };
    in
    mkIf (isDesktop && isLinux && enable) {
      packages = [ pkgs.ashell ];

      xdg.config.files."ashell/config.toml".source = toml.generate "ashell.toml" settings;
    };
}
