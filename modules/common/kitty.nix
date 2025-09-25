{ config, lib, ... }: let
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
        conform_os_window_close = 0;

        focus_follows_mouse = false;
        mouse_hide_wait     = 0;

        enable_audio_bell = false;

        window_padding_width = config.theme.padding;
        window_border_width = "0pt";

        cursor     = base05;
        background = base00;
        foreground = base05;
      };
    };
  }];
}

