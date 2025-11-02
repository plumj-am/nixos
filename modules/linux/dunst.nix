{ config, lib, ... }: let
  inherit (lib) mkIf disabled;
in mkIf config.isDesktopNotWsl {
  home-manager.sharedModules = [{
    services.dunst = with config.theme.withHash; disabled {
      iconTheme.name    = config.theme.icons.name;
      iconTheme.package = config.theme.icons.package;
      iconTheme.size    = "32";

      settings.global = {
        dmenu              = "fuzzel --dmenu";
        show_age_threshold = 30;
        transparency       = 0;  # Doesn't work on Wayland.
        separator_height   = config.theme.border.normal;
        sort               = "update";
        format             = "<b>%a</b>\n<b>%s</b>\n%b";

        enable_recursive_icon_lookup = true;

        monitor = if config.networking.hostName == "yuzu" then 1 else 0;
        font    = "${config.theme.font.sans.name}:size=${toString config.theme.font.size.normal}";
        width   = ''(350, 500)'';
        height  = ''(0, 750)'';
        offset  = ''(${toString config.theme.margin.normal}, ${toString config.theme.margin.normal})'';

        padding            = config.theme.padding.normal;
        horizontal_padding = config.theme.padding.normal;
        corner_radius      = config.theme.radius.big;
        frame_width        = config.theme.border.normal;

        progress_bar_min_width     = 0;
        progress_bar_max_width     = 750;
        progress_bar_corner_radius = config.theme.radius.normal;
      };

      settings.urgency_low = {
        frame_color = "${base0E}";
        highlight   = "${base0E}";
        background  = "${base00}";
        foreground  = "${base04}";
        timeout     = 10;
      };

      settings.urgency_normal = {
        frame_color = "${base09}";
        highlight   = "${base09}";
        background  = "${base00}";
        foreground  = "${base04}";
        timeout     = 20;
      };

      settings.urgency_critical = {
        frame_color = "${base08}";
        highlight   = "${base08}";
        background  = "${base00}";
        foreground  = "${base04}";
        timeout     = 30;
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
