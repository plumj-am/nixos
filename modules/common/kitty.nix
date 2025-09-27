{ pkgs, config, lib, ... }: let
  inherit (lib) enabled mkIf;
in{
  home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    programs.kitty = with config.theme.withHash; enabled {
      font = {
        name    = config.theme.font.mono.family;
        package = config.theme.font.mono.package;
        size    = config.theme.font.size.normal;
      };

      settings = {
        allow_remote_control    = true;
        confirm_os_window_close = 0;

        scrollback_lines = 100000;
        scrollback_pager = "bat --chop-long-lines";

        mouse_hide_wait = 0;

        enable_audio_bell = false;

        strip_trailing_spaces = "always";

        # Performance
        repaint_delay   = 1;
        input_delay     = 1;
        sync_to_monitor = false;

        window_padding_width = config.theme.padding / 2;
        window_border_width  = "0pt";

        cursor                  = base05;
        cursor_text_color       = base00;
        background              = base00;
        foreground              = base05;
        active_tab_background   = base00;
        active_tab_foreground   = base05;
        inactive_tab_background = base01;
        inactive_tab_foreground = base05;
        selection_background    = base02;
        selection_foreground    = base00;
        url_color               = base0D;

        color0  = base00;
        color1  = base08;
        color2  = base0B;
        color3  = base0A;
        color4  = base0D;
        color5  = base0E;
        color6  = base0C;
        color7  = base05;
        color8  = base03;
        color9  = base08;
        color10 = base0B;
        color11 = base0A;
        color12 = base0D;
        color13 = base0E;
        color14 = base0C;
        color15 = base07;
        color16 = base09;
        color17 = base0F;
        color18 = base01;
        color19 = base02;
        color20 = base04;
        color21 = base06;
      };
    };
    # Desktop entry for Zellij in Fuzzel.
    xdg.desktopEntries.zellij-kitty = {
      name     = "Zellij Kitty";
      icon     = "kitty";
      exec     = "kitty ${pkgs.zellij}/bin/zellij";
      terminal = false;
    };
  }];
}

