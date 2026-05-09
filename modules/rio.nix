{
  flake.modules.common.rio =
    {
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
      inherit (lib') mkDesktopEntry;
      inherit (config) theme;
    in
    {
      hjem.extraModule = {
        packages = [
          pkgs.rio

          (mkDesktopEntry {
            name = "Zellij-Rio";
            exec = "rio --command zellij";
          })
        ];

        xdg.config.files = {
          "rio/config.toml" = {
            generator = pkgs.writers.writeTOML "rio-config.toml";
            value = {
              fonts = {
                family = theme.font.mono.name;
                # For Maple Mono
                # features = [
                #   "+cv64"
                #   "+ss03"
                #   "+ss05"
                #   "+ss07"
                #   "+ss08"
                #   "+ss09"
                #   "+ss10"
                #   "+ss11"
                # ];
              };
              draw-bold-text-with-light-colors = false;

              shell.program = getExe pkgs.nushell;
              navigation.mode = "Plain";
              scrollback-history-limit = 100000;
              confirm-before-quit = false;

              theme = "gruvbox";
              hide-mouse-cursor-when-typing = true;
              window.decorations = "Disabled";
              padding = singleton theme.padding.tiny;

              # Waiting for fix <https://github.com/raphamorim/rio/issues/1407>
              # hints = {
              #   alphabet = "jfkdls;ahgurieowpq";
              #   rules = singleton {
              #     regex = ''(https://|http://)[^\u{0000}-\u{001F}\u{007F}-\u{009F}<>"\s{-}\^⟨⟩`\\]+'';
              #     hyperlinks = true;
              #     post-processing = true;
              #     persist = false;
              #     action.command = "xdg-open";
              #   };
              # };

              renderer = {
                backend = "Vulkan";
                target_fps = 560;
              };
            };
          };

          "rio/themes/gruvbox.toml" = {
            generator = pkgs.writers.writeTOML "rio-themes-gruvbox.toml";
            value = with theme.withHash; {
              colors = {
                background = base00;
                foreground = base05;
                selection-background = base02;
                selection-foreground = base00;
                cursor = base05;
                black = base00;
                light-black = base00;
                red = base08;
                light-red = base08;
                green = base0B;
                light-green = base0B;
                yellow = base0A;
                light-yellow = base0A;
                blue = base0D;
                light-blue = base0D;
                magenta = base0E;
                light-magenta = base0E;
                cyan = base0C;
                light-cyan = base0C;
                white = base05;
                light-white = base05;
              };
            };
          };
        };
      };
    };
}
