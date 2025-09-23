{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {

  home-manager.sharedModules = [{
    programs.waybar = with config.theme.withHashtag; enabled {
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 12;

          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [ "tray" "pulseaudio" "cpu" "memory" "network" "battery" "clock" ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              default = "";
              active = "";
            };
            persistent-workspaces."*" = 4;
          };

          "hyprland/window" = {
            max-length = 50;
            separate-outputs = true;
            rewrite = {
              "(.*) — Zen Browser" = "󰖟 $1";
              "(.*) - Discord" = "󰙯 $1";
              "(.*) — nu" = " $1";
            };
          };

          tray = {
            reverse-direction = true;
            spacing = 5;
          };

          pulseaudio = {
            format = "{format_source} {icon} {volume}%";
            format-muted = "{format_source} 󰸈";
            format-source = "󰍬";
            format-source-muted = "󰍭";
            format-icons = {
              default = [ "󰕿" "󰖀" "󰕾" ];
            };
            on-click = "pavucontrol";
            on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            tooltip = true;
            tooltip-format = "Volume: {volume}%\nClick: Open audio manager\nRight-click: Mute toggle";
          };

          cpu = {
            format = "󰘚 {usage}%";
            tooltip = true;
            tooltip-format = "CPU Usage: {usage}%\nLoad: {load}";
            interval = 1;
            states = {
              warning = 70;
              critical = 90;
            };
          };

          memory = {
            format = "󰽘 {used:0.1f}G/{total:0.1f}G";
            tooltip = true;
            tooltip-format = "Memory: {used:0.1f}G/{total:0.1f}G ({percentage}%)\nAvailable: {avail:0.1f}G";
            interval = 1;
            states = {
              warning = 70;
              critical = 90;
            };
          };

          network = {
            format-wifi = " {essid} {signalStrength}%";
            format-ethernet = "󰈀 {ipaddr}";
            format-disconnected = "󰤮 Disconnected";
            format-linked = " {ifname} (No IP)";
            tooltip = true;
            tooltip-format-wifi = "Network: {essid}\nSignal: {signalStrength}%\nSpeed: {bandwidthDownBits}/{bandwidthUpBits}";
            tooltip-format-ethernet = "Ethernet: {ifname}\nIP: {ipaddr}/{cidr}";
            on-click = "nm-connection-editor";
          };

          battery = {
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󰂄 {capacity}%";
            format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            tooltip = true;
            tooltip-format = "Battery: {capacity}%\nTime: {time}\nHealth: {health}%";
            states = {
              warning = 30;
              critical = 15;
            };
          };

          clock = {
            interval = 1;
            format = " {:%Y-%m-%d | %H:%M:%S}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };
        };
      };

      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: "${config.theme.font.mono.name}";
          font-size: 13px;
          margin: 0;
          padding: 0;
        }

        #waybar {
          background: ${base00};
          color: ${base07};
        }

        #window {
          color: ${base07};
        }

        #workspaces button:nth-child(1) { color: ${base08}; }
        #workspaces button:nth-child(2) { color: ${base09}; }
        #workspaces button:nth-child(3) { color: ${base0A}; }
        #workspaces button:nth-child(4) { color: ${base0B}; }
        #workspaces button:nth-child(5) { color: ${base0C}; }
        #workspaces button:nth-child(6) { color: ${base0D}; }
        #workspaces button:nth-child(7) { color: ${base0E}; }
        #workspaces button:nth-child(8) { color: ${base0F}; }

        #workspaces button { padding: 0 10px; }

        #workspaces button.empty {
          color: ${base03};
        }

        #workspaces button.active {
          color: ${base07};
          background: ${base02};
        }

        #tray, #pulseaudio, #cpu, #memory, #network, #battery, #clock {
          margin: 0;
          margin-left: ${toString config.theme.margin}px;
          padding: 0 ${toString config.theme.padding}px;
          color: ${base07}; /* Use highest contrast text */
        }

        #battery.critical:not(.charging) {
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
          color: ${base08};
        }

        #cpu.warning, #memory.warning {
          color: ${base0A};
        }

        #cpu.critical, #memory.critical {
          color: ${base08};
          animation-name: blink;
          animation-duration: 1s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }


        @keyframes blink {
          to {
            color: ${base05};
          }
        }
      '';
    };
  }];
}
