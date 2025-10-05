{ lib, config, ... }: let
  inherit (lib) enabled mkIf;
in {

  home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    programs.qutebrowser = enabled {
      settings = {
        tabs = {
          position             = "left";
          show                 = "always";
          indicator.width      = 2;
          favicons.scale       = 0.8;
          mousewheel_switching = false;
          mode_on_change       = "restore";
        };

        keyhint.delay     = 0;
        completion.height = "25%";
        completion.shrink = true;
        messages.timeout  = 10000;

        prompt.radius  = config.theme.radius;
        keyhint.radius = config.theme.radius;
        hints.radius   = config.theme.radius;

        fonts.default_family = config.theme.font.mono.family;

        colors.webpage.darkmode.enabled = config.theme.is_dark;

        session.lazy_restore        = true;
        auto_save.session           = true;
        content.autoplay            = false;
        input.insert_mode.auto_load = true;

        statusbar.widgets = [
          "progress"
          "keypress"
          "search_match"
          "url"
          "scroll"
          "history"
          "tabs"
          "text:qute "
        ];
      };

      keyBindings.normal = {
        "d"        = "nop";
        "J"        = "tab-prev";
        "K"        = "tab-next";
        "<Space>f" = "cmd-set-text -s :open -tr";
        "<Space>b" = "cmd-set-text -s :tab-select";
      };

      extraConfig = ''
        c.tabs.padding = {"top": 0, "bottom": 0, "left": 0, "right": 0}

        c.url.searchengines = {
            "DEFAULT": "https://duckduckgo.com/?q={}",
            "!gh": "https://github.com/search?o=desc&q={}&s=stars",
            "!yt": "https://www.youtube.com/results?search_query={}",
            "!rs": "https://doc.rust-lang.org/nightly/reference/?search={}",
            "!rsby": "https://doc.rust-lang.org/rust-by-example/index.html?search={}",
            "!ca": "https://crates.io/search?q={}",
        }
      '';
    };
  }];
}
