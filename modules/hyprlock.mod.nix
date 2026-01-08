{
  config.flake.modules.homeModules.hyprlock =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;

      yuzuMonitor = # mkIf (config.networking.hostName == "yuzu")
        "DP-2";
    in
    {
      programs.hyprlock = {
        enable = true;
        settings = {
          font-name = "${config.theme.font.sans.name} ${toString config.theme.font.size.small}";

          general = {
            hide_cursor = true;
            ignore_empty_input = true;
            immediate_render = true;
          };

          animations.enabled = false;

          background = [
            {
              color = "rgba(0,0,0,1.0)";
              path = "screenshot";
              brightness = 0.4;
              blur_passes = 3;
            }
          ];

          input-field = [
            {
              size = "400, 50";
              position = "0, -80";
              monitor = yuzuMonitor;
              font_family = config.theme.font.mono.family;
              fade_on_empty = false;
            }
          ];

          label = [
            {
              monitor = yuzuMonitor;
              text = ''cmd[update:18000000] echo "<b> "$(date +'%A, %-d %B %Y')" </b>"'';
              font_size = 24;
              font_family = config.theme.font.mono.family;
              position = "0, -150";
              halign = "center";
              valign = "top";
            }
            {
              monitor = yuzuMonitor;
              text = ''cmd[update:1000] echo "<b><big> $(date +"%H:%M:%S") </big></b>"'';
              font_size = 64;
              font_family = config.theme.font.mono.family;
              position = "0, 0";
              halign = "center";
              valign = "center";
            }
            {
              monitor = yuzuMonitor;
              text = "$USER";
              font_size = 16;
              font_family = config.theme.font.mono.family;
              position = "0, 100";
              halign = "center";
              valign = "bottom";
            }
            {
              monitor = yuzuMonitor;
              text = ''cmd[update:1000] echo "<b> Uptime: $(cat /proc/uptime | awk '{printf "%.0f", $1}' | awk '{days=int($1/86400); hours=int(($1%86400)/3600); minutes=int(($1%3600)/60); seconds=$1%60; printf "%dd %dh %dm %ds", days, hours, minutes, seconds}') </b>"'';
              font_size = 12;
              font_family = config.theme.font.mono.family;
              position = "0, -200";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };
    };
}
