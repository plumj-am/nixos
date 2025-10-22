{ pkgs, lib, config, ... }: let
  inherit (lib) enabled mkIf mapAttrsToList;
in mkIf config.isDesktopNotWsl {
  home-manager.sharedModules = [{
    programs.ghostty = enabled {
      clearDefaultKeybinds = true;

      installBatSyntax = true;

      settings = with config.theme; {
        font-size   = font.size.normal;
        font-family = font.mono.name;

        theme = "custom";

        window-padding-x  = padding.small;
        window-padding-y  = padding.small;
        window-decoration = false;

        scrollback-limit = 100 * 1024 * 1024; # 100 MiB

        mouse-hide-while-typing = true;

        confirm-close-surface         = false;
        quit-after-last-window-closed = true;

        keybind = mapAttrsToList (name: value: "ctrl+shift+${name}=${value}") {
          c = "copy_to_clipboard";
          v = "paste_from_clipboard";

          i = "inspector:toggle";

          plus  = "increase_font_size:1";
          minus = "decrease_font_size:1";
          equal = "reset_font_size";
        };
      };

      themes = with config.theme.withHash; {
        custom = {
          background           = base00;
          cursor-color         = base05;
          foreground           = base05;
          selection-background = base02;
          selection-foreground = base00;
          palette = mapAttrsToList (name: value: "${name}=${value}") {
            "0"  = base00;
            "1"  = base01;
            "2"  = base02;
            "3"  = base03;
            "4"  = base04;
            "5"  = base05;
            "6"  = base06;
            "7"  = base07;
            "8"  = base08;
            "9"  = base09;
            "10" = base0A;
            "11" = base0B;
            "12" = base0C;
            "13" = base0D;
            "14" = base0E;
            "15" = base0F;
          };
        };
      };
    };
    # Desktop entry for Zellij in Fuzzel.
    xdg.desktopEntries.zellij-ghostty = {
      name     = "Zellij Ghostty";
      icon     = "ghostty";
      exec     = "ghostty -e ${pkgs.zellij}/bin/zellij";
      terminal = false;
    };
  }];
}
