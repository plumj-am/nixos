let
  hyprlockBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) theme;
      inherit (config.networking) hostName;

      fontFamily = "${theme.font.sans.name}";

      uptime = ''"<b> Uptime: $(cat /proc/uptime | awk '{printf "%.0f", $1}' | awk '{days=int($1/86400); hours=int(($1%86400)/3600); minutes=int(($1%3600)/60); seconds=$1%60; printf "%dd %dh %dm %ds", days, hours, minutes, seconds}') </b>"'';

      yuzuMonitor = if hostName == "yuzu" then "DP-2" else "";
    in
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.hyprlock;

        xdg.config.files."hypr/hyprlock.conf".text = # conf
          ''
            general {
              hide_cursor = true
              ignore_empty_input = true
              immediate_render = true
            }

            animations {
              enabled = false
            }

            background {
              color = rgba(0,0,0,1.0)
              path = screenshot
              brightness = 0.4
              blur_passes = 3
            }

            input-field {
              size = 400, 50
              position = 0, -80
              monitor = ${yuzuMonitor}
              font_family = ${fontFamily}
              fade_on_empty = false
            }

            label {
              monitor = ${yuzuMonitor}
              text = cmd[update:18000000] echo "<b> $(date +'%A, %-d %B %Y') </b>"
              font_size = 24
              font_family = ${fontFamily}
              position = 0, -150
              halign = center
              valign = top
            }

            label {
              monitor = ${yuzuMonitor}
              text = cmd[update:1000] echo "<b><big> $(date +'%H:%M:%S') </big></b>"
              font_size = 64
              font_family = ${fontFamily}
              position = 0, 0
              halign = center
              valign = center
            }
            label {
              monitor = ${yuzuMonitor}
              text = $USER
              font_size = 16
              font_family = ${fontFamily}
              position = 0, 100
              halign = center
              valign = bottom
            }
            label {
              monitor = ${yuzuMonitor}
              text = cmd[update:1000] echo ${uptime}
              font_size = 12
              font_family = ${fontFamily}
              position = 0, -200
              halign = center
              valign = center
            }
          '';
      };
    };
in
{
  flake.modules.nixos.hyprlock = hyprlockBase;
}
