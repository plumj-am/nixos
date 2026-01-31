{
  flake.modules.hjem.kitty =
    {
      pkgs,
      lib,
      myLib,
      theme,
      isDesktop,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (myLib) mkDesktopEntry;
      inherit (lib.generators) mkKeyValueDefault;
      inherit (pkgs.formats) keyValue;

      kittyKeyValueGen = keyValue {
        listsAsDuplicateKeys = true;
        mkKeyValue = mkKeyValueDefault { } " ";
      };

      settings = with theme.withHash; {
        font_family = theme.font.mono.name;
        font_size = theme.font.size.term;
        font_features = ''
          MapleMono-NF-Regular +cv64 +ss03 +ss05 +ss07 +ss08 +ss09 +ss10 +ss11
          MapleMono-NF-Italic +cv64 +ss03 +ss05 +ss07 +ss08 +ss09 +ss10 +ss11
          MapleMono-NF-Bold +cv64 +ss03 +ss05 +ss07 +ss08 +ss09 +ss10 +ss11
        '';

        allow_remote_control = "yes";
        confirm_os_window_close = 0;

        scrollback_lines = 100000;
        scrollback_pager = "bat --chop-long-lines";

        mouse_hide_wait = 0;

        enable_audio_bell = false;

        strip_trailing_spaces = "always";

        # Performance
        repaint_delay = 1;
        input_delay = 1;
        sync_to_monitor = false;

        hide_window_decorations = true;
        window_padding_width = theme.padding.small;
        window_border_width = "0pt";

        cursor = base05;
        cursor_text_color = base00;
        background = base00;
        foreground = base05;
        active_tab_background = base00;
        active_tab_foreground = base05;
        inactive_tab_background = base01;
        inactive_tab_foreground = base05;
        selection_background = base02;
        selection_foreground = base00;
        url_color = base0D;

        color0 = base00;
        color1 = base08;
        color2 = base0B;
        color3 = base0A;
        color4 = base0D;
        color5 = base0E;
        color6 = base0C;
        color7 = base05;
        color8 = base03;
        color9 = base08;
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

      enable = true;
    in
    mkIf (isDesktop && enable) {
      packages = [
        pkgs.kitty

        (mkDesktopEntry { inherit pkgs; } {
          name = "Zellij-kitty";
          exec = "kitty -e ${pkgs.zellij}/bin/zellij";
        })
      ];

      xdg.config.files."kitty/kitty.conf".source = kittyKeyValueGen.generate "kitty.conf" settings;
    };
}
