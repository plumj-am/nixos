{
  config.flake.modules.nixos.waybar = {
    programs.waybar.enable = true;
  };

  config.flake.modules.hjem.waybar =
    {
      lib,
      theme,
      isDesktop,
      isLinux,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (builtins) concatStringsSep map toString;

      enable = true;
    in
    mkIf (isDesktop && isLinux && enable) {
      xdg.config.files."waybar/config.jsonc".text =
        # jsonc
        ''
          {
            "layer": "top",
            "height": ${toString theme.margin.big},
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
              "on-click": "pwvucontrol",
              "on-click-right": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
              "tooltip": true,
              "tooltip-format": "Volume: {volume}%\nClick: Open audio manager\nRight-click: Mute toggle"
            },

            "cpu": {
              "format": "󰘚  {usage}%",
              "tooltip": true,
              "tooltip-format": "CPU Usage: {usage}%\nLoad: {load}",
              "interval": 2,
              "on-click": "kitty btop",
              "states": {
                "warning": 70,
                "critical": 90
              }
            },

            "memory": {
              "format": "󰽘  {used:0.1f}G/{total:0.1f}G",
              "tooltip": true,
              "tooltip-format": "Memory: {used:0.1f}G/{total:0.1f}G ({percentage}%)\nAvailable: {avail:0.1f}G",
              "interval": 2,
              "on-click": "kitty btop",
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
              "interval": 300,
              "states": {
                "warning": 70,
                "critical": 90
              }
            },

            "custom/gpu": {
              "exec": "bash -c 'if command -v nvidia-smi >/dev/null; then nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1; elif command -v radeontop >/dev/null; then radeontop -d - -l 1 | grep -o \"gpu [0-9]*\" | cut -d\" \" -f2; else echo \"N/A\"; fi'",
              "format": "󰢮  {}%",
              "interval": 5,
              "tooltip": true,
              "tooltip-format": "GPU Usage: {}%\nClick: Open system monitor",
              "on-click": "kitty btop",
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
            font-size: ${toString theme.font.size.small}px;
            margin: 0;
            padding: 0;
          }

          #waybar {
            background:
              linear-gradient(rgba(${concatStringsSep ", " (map toString theme.withRgb.base00)}, ${toString theme.opacity.verylow}), rgba(${concatStringsSep ", " (map toString theme.withRgb.base00)}, ${toString theme.opacity.verylow})) padding-box,
              linear-gradient(225deg, ${base0B}, ${base09}) border-box;
            color: ${base07};
            border: ${toString theme.border.small}px solid transparent;
            border-radius: ${toString theme.radius.small}px;
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

          #cpu, #memory, #disk, #custom-gpu {
            min-width: 36px;
          }


          #battery.critical:not(.charging) {
            animation-name: blink;
            animation-duration: ${toString theme.duration.s.short}s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
            color: ${base08};
          }

          #cpu.warning, #memory.warning, #disk.warning {
            color: ${base0A};
          }

          #cpu.critical, #memory.critical, #disk.critical, #custom-gpu.critical {
            color: ${base08};
            animation-name: blink;
            animation-duration: ${toString theme.duration.s.normal}s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
          }

          #cpu.warning, #memory.warning, #disk.warning, #custom-gpu.warning {
            color: ${base0A};
          }


          @keyframes blink {
            to {
              color: ${base05};
            }
          }
        '';
    };
}
