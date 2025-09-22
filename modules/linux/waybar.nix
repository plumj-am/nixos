{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {

  home-manager.sharedModules = [{
    programs.waybar = with config.theme.withHashtag; enabled {
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 24;

          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [ "tray" "pulseaudio" "cpu" "memory" "network" "battery" "clock" ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              default = "";
              active = "";
            };
            persistent-workspaces."*" = 8;
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
          };

          cpu = {
            format = " {usage}%";
            tooltip = false;
          };

          memory = {
            format = "󰽘 {}%";
            tooltip = false;
          };

          network = {
            format-wifi = " {signalStrength}%";
            format-ethernet = "󰈀 {ipaddr}/{cidr}";
            format-disconnected = "󰤮 ";
            format-linked = " {ifname} (No IP)";
          };

          battery = {
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󰂄 {capacity}%";
            format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            states = {
              warning = 30;
              critical = 15;
            };
          };

          clock = {
            interval = 60;
            format = "{:%H:%M}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };
        };
      };

      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: "${config.theme.font.mono.name}";
          font-size: 11px;
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

        #workspaces button.empty {
          color: ${base03};
        }

        #workspaces button.active {
          color: ${base07};
          background: ${base02};
        }

        #tray, #pulseaudio, #cpu, #memory, #network, #battery, #clock {
          margin-left: 10px;
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

        @keyframes blink {
          to {
            color: ${base05};
          }
        }
      '';
    };
  }];
}
