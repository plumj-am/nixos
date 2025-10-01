{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {
  home-manager.sharedModules = [{
    services.dunst = with config.theme.withHash; enabled {
      iconTheme.name    = config.theme.icons.name;
      iconTheme.package = config.theme.icons.package;
      iconTheme.size    = "32";

      settings.global = {
        dmenu              = "fuzzel --dmenu";
        show_age_threshold = 0;
        transparency       = 0;
        separator_height   = 0;
        padding            = config.theme.padding;
        horizontal_padding = config.theme.padding;
        frame_width        = 1;
        frame_color        = "${base00}";

        monitor = if config.networking.hostName == "yuzu" then 1 else 0;

        font = "${config.theme.font.mono.name}:size=${toString config.theme.font.size.normal}";

      };

      settings.urgency_low = {
        background = "${base0E}";
        foreground = "${base07}";
        timeout    = 10;
      };

      settings.urgency_normal = {
        background = "${base0D}";
        foreground = "${base07}";
        timeout    = 20;
      };

      settings.urgency_critical = {
        background = "${base08}";
        foreground = "${base07}";
        timeout    = 30;
      };

      settings.general = {
        appname = "*";
        summary = "*";
        body    = "*download*|*steam*|*now playing*|*error*|*failed*|*success*|*complete*";
        urgency = "normal";
      };
    };
  }];
}
