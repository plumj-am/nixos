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

          modules-left   = [ "hyprland/workspaces" "niri/workspaces" ];
          modules-center = [ "hyprland/window" "niri/window" ];
          modules-right  = [ "tray" "pulseaudio" "cpu" "memory" "disk" "custom/gpu" "battery" "clock" ];

          "hyprland/workspaces" = {
            all-outputs  = true;
            format       = "{icon}";
            format-icons = {
              default = "○";
              active  = "●";
            };
            persistent-workspaces."*" = 4;
          };

          "niri/workspaces" = {
            all-outputs  = true;
            format       = "{index}";
          };

          "hyprland/window" = {
            max-length       = 50;
            separate-outputs = true;
            rewrite          = {
              "(.*) — Zen Browser" = "󰖟 $1";
              "(.*) - Discord"     = "󰙯 $1";
              "(.*) — nu"          = " $1";
            };
          };

          "niri/window" = {
            max-length       = 50;
            separate-outputs = true;
            rewrite          = {
              "(.*) — Zen Browser" = "󰖟 $1";
              "(.*) - Discord"     = "󰙯 $1";
              "(.*) — nu"          = " $1";
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
            format-source-muted = ""; # 󰍭
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

      style = /* css */ ''
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
            linear-gradient(rgba(${builtins.concatStringsSep ", " (map toString config.theme.withRgb.base00)}, 0.8), rgba(${builtins.concatStringsSep ", " (map toString config.theme.withRgb.base00)}, 0.8)) padding-box,
            linear-gradient(225deg, ${base0B}, ${base09}) border-box;
          color: ${base07};
          border: ${toString (config.theme.border / 2)}px solid transparent;
          border-radius: ${toString (config.theme.radius * 2)}px;
        }

        #window {
          color: ${base07};
        }

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
          background: rgba(${builtins.concatStringsSep ", " (map toString config.theme.withRgb.base00)}, 0.45) padding-box;
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
