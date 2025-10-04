{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {

  home-manager.sharedModules = [{
    programs.waybar = with config.theme.withHash; enabled {
      settings = {
        mainBar = {
          layer        = "top";
          height       = config.theme.radius * 8;
          margin-top   = config.theme.margin;
          margin-left  = config.theme.margin;
          margin-right = config.theme.margin;

          modules-left   = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right  = [ "tray" "pulseaudio" "cpu" "memory" "disk" "custom/gpu" "battery" "clock" ];

          "hyprland/workspaces" = {
            format       = "{icon}";
            format-icons = {
              default = "○";
              active  = "●";
            };

            persistent-workspaces."*" = 4;
          };

          "hyprland/window" = {
            max-length       = 50;
            separate-outputs = true;
            rewrite          = {
              "(.*) — Zen Browser" = "󰖟 $1";
              "(.*) - Discord" = "󰙯 $1";
              "(.*) — nu" = " $1";
            };
          };

          tray = {
            reverse-direction = true;
            spacing           = 5;
          };

          pulseaudio = {
            format              = "{format_source} {icon} {volume}%";
            format-muted        = "{format_source} 󰸈";
            format-source       = "󰍬";
            format-source-muted = "󰍭";
            format-icons        = {
              default = [ "󰕿" "󰖀" "󰕾" ];
            };
            on-click       = "pwvucontrol";
            on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            tooltip        = true;
            tooltip-format = "Volume: {volume}%\nClick: Open audio manager\nRight-click: Mute toggle";
          };

          cpu = {
            format         = "󰘚 {usage}%";
            tooltip        = true;
            tooltip-format = "CPU Usage: {usage}%\nLoad: {load}";
            interval       = 2;
            on-click       = "kitty btop";
            states         = {
              warning  = 70;
              critical = 90;
            };
          };

          memory = {
            format         = "󰽘 {used:0.1f}G/{total:0.1f}G";
            tooltip        = true;
            tooltip-format = "Memory: {used:0.1f}G/{total:0.1f}G ({percentage}%)\nAvailable: {avail:0.1f}G";
            interval       = 2;
            on-click       = "kitty btop";
            states         = {
              warning  = 70;
              critical = 90;
            };
          };

          disk = {
            format         = "󰋊 {percentage_used}%";
            path           = "/";
            tooltip        = true;
            tooltip-format = "Disk: {used}/{total} ({percentage_used}%)\nAvailable: {free}";
            interval       = 300;
            states         = {
              warning  = 70;
              critical = 90;
            };
          };


          "custom/gpu" = {
            exec           = "bash -c 'if command -v nvidia-smi >/dev/null; then nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1; elif command -v radeontop >/dev/null; then radeontop -d - -l 1 | grep -o \"gpu [0-9]*\" | cut -d\" \" -f2; else echo \"N/A\"; fi'";
            format         = "󰢮 {}%";
            interval       = 5;
            tooltip        = true;
            tooltip-format = "GPU Usage: {}%\nClick: Open system monitor";
            on-click       = "kitty btop";
            states         = {
              warning  = 70;
              critical = 90;
            };
          };

          battery = {
            format          = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged  = "󰂄 {capacity}%";
            format-icons    = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            tooltip         = true;
            tooltip-format  = "Battery: {capacity}%\nTime: {time}\nHealth: {health}%";
            states          = {
              warning  = 30;
              critical = 15;
            };
          };

          clock = {
            interval       = 1;
            format         = " {:%Y-%m-%d | %H:%M:%S}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

        };
      };

      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: "${config.theme.font.mono.name}";
          font-size: ${toString config.theme.font.size.small}px;
          margin: 0;
          padding: 0;
        }

        #waybar {
          background:
            linear-gradient(rgba(${builtins.concatStringsSep ", " (map toString config.theme.withRgb.base00)}, 0.85), rgba(${builtins.concatStringsSep ", " (map toString config.theme.withRgb.base00)}, 0.85)) padding-box,
            linear-gradient(225deg, ${base0A}, ${base08}) border-box;
          color: ${base07};
          border: ${toString (config.theme.border / 2)}px solid transparent;
          border-radius: ${toString (config.theme.radius * 2)}px;
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

        #workspaces button {
          padding: 0 ${toString config.theme.padding}px;
          border: ${toString (config.theme.border / 2)}px solid transparent;
          border-radius: ${toString config.theme.radius}px;
        }

        #workspaces button.empty {
          color: ${base03};
        }

        #workspaces button.active {
          color: ${base07};
          background:
            linear-gradient(${base02}, ${base02}) padding-box,
            linear-gradient(45deg, ${base0A}, ${base08}) border-box;
          border: ${toString (config.theme.border / 2)}px solid transparent;
        }

        #tray, #pulseaudio, #cpu, #memory, #disk, #battery, #clock, #custom-gpu {
          margin: 0;
          margin-left: ${toString config.theme.margin}px;
          padding: 0 ${toString config.theme.padding}px;
          color: ${base07}; /* Use highest contrast text */
        }

        #cpu, #memory, #disk, #custom-gpu {
          min-width: 36px;
        }


        #battery.critical:not(.charging) {
          animation-name: blink;
          animation-duration: 0.5s;
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
          animation-duration: 1s;
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
  }];
}
