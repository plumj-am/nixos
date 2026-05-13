{
  flake.modules.common.ghostty =
    {
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrsToList mapAttrs' nameValuePair;
      inherit (lib'.generators) keyValueEqualsSep;
      inherit (lib') mkDesktopEntry;
      inherit (config) theme;

      # Thank you to: <https://github.com/snugnug/hjem-rum/blob/main/modules/collection/programs/ghostty.nix>
      # for `mkTheme`.
      mkThemes =
        themes:
        mapAttrs' (
          name: value:
          nameValuePair "ghostty/themes/${name}" {
            generator = keyValueEqualsSep.generate "ghostty-${name}-theme";
            inherit value;
          }
        ) themes;

      themes = with theme.withHash; {
        custom = {
          background = base00;
          cursor-color = base05;
          foreground = base05;
          selection-background = base02;
          selection-foreground = base00;
          palette = mapAttrsToList (name: value: "${name}=${value}") {
            "0" = base00;
            "1" = base01;
            "2" = base02;
            "3" = base03;
            "4" = base04;
            "5" = base05;
            "6" = base06;
            "7" = base07;
            "8" = base08;
            "9" = base09;
            "10" = base0A;
            "11" = base0B;
            "12" = base0C;
            "13" = base0D;
            "14" = base0E;
            "15" = base0F;
          };
        };
      };
    in
    {
      hjem.extraModule = {
        packages = [
          pkgs.ghostty

          (mkDesktopEntry {
            name = "Zellij-Ghostty";
            exec = "ghostty -e ${pkgs.zellij}/bin/zellij";
          })
        ];

        xdg.config.files = {
          "ghostty/config" = {
            generator = keyValueEqualsSep.generate "ghostty-config";
            value = with theme; {
              font-size = font.size.tiny;
              font-family = font.mono.name;
              font-feature = "+calt, +liga, +dlig";

              theme = if theme.colorScheme == "matugen" then "custom" else theme.ghostty;

              window-padding-x = padding.small;
              window-padding-y = padding.small;
              window-decoration = false;

              split-preserve-zoom = "navigation";

              scrollback-limit = 100 * 1024 * 1024; # 100 MiB

              mouse-hide-while-typing = true;

              copy-on-select = true;

              confirm-close-surface = false;
              quit-after-last-window-closed = true;

              keybind =
                mapAttrsToList (name: value: "ctrl+shift+${name}=${value}") {
                  c = "copy_to_clipboard";
                  v = "paste_from_clipboard";

                  i = "inspector:toggle";

                  plus = "increase_font_size:1";
                  minus = "decrease_font_size:1";
                  equal = "reset_font_size";

                  e = "write_scrollback_file:open";

                  j = "scroll_page_lines:1";
                  k = "scroll_page_lines:-1";

                  u = "scroll_page_fractional:-0.5";
                  d = "scroll_page_fractional:0.5";

                  z = "jump_to_prompt:-2";
                  x = "jump_to_prompt:2";

                  # ugly tabs :(
                  t = "new_window";
                  n = "new_window";

                  w = "unbind";
                  q = "unbind";
                }
                ++ mapAttrsToList (name: value: "alt+${name}=${value}") {
                  h = "goto_split:left";
                  j = "goto_split:down";
                  k = "goto_split:up";
                  l = "goto_split:right";
                  f = "toggle_split_zoom";
                }
                ++ mapAttrsToList (name: value: "alt+shift+${name}=${value}") {
                  j = "new_split:down";
                  l = "new_split:right";
                };
            };
          };
        }
        // mkThemes themes;
      };
    };
}
