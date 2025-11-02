{ lib, config, ... }: let
  inherit (lib) enabled mkIf genAttrs const merge;
in {

  home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    programs.qutebrowser = enabled {
      settings = {
        tabs = {
          position             = "left";
          show                 = "always";
          show_switching_delay = 3000;
          indicator.width      = 2;
          favicons.scale       = 0.8;
          mousewheel_switching = false;
          mode_on_change       = "restore";
          title.format         = "{audio}{aligned_index}: {current_title}";
          title.format_pinned  = "{audio}{aligned_index}: {current_title}";
          undo_stack_size      = 1000;
        };

        editor.command = ["ghostty" "-e" "hx" "{file}:{line}:{column}"];

        completion = {
          height                = "33%";
          shrink                = true;
          cmd_history_max_items = 100000;
          use_best_match        = true;
        };

        content.cookies.accept = "no-unknown-3rdparty";

        keyhint.delay             = 0;
        messages.timeout          = 5000;
        downloads.remove_finished = 30000;

        prompt.radius  = config.theme.radius.normal;
        keyhint.radius = config.theme.radius.normal;
        hints.radius   = config.theme.radius.normal;

        fonts.default_family = config.theme.font.sans.name;
        fonts.web.family     = genAttrs
          [ "sans_serif" "serif" "standard" ]
          (const (config.theme.font.sans.name));

        colors = with config.theme.withHash; merge {
          webpage.darkmode.enabled = config.theme.is_dark;

        # Background.
        } <| (genAttrs [ "statusbar.command.bg" "statusbar.normal.bg" "tabs.odd.bg" "tabs.selected.even.fg" "tabs.selected.odd.fg" "tabs.pinned.selected.even.fg" "tabs.pinned.selected.odd.fg" "tabs.pinned.odd.fg" "tabs.pinned.even.fg" ]
          (const base00)

        # Background 1.
        ) // (genAttrs [ "tabs.even.bg" ]
          (const base01)

        # Background 2.
        ) // (genAttrs [ "tabs.bar.bg" ]
          (const base02)

        # Foreground.
        ) // (genAttrs [ "statusbar.command.fg" "statusbar.normal.fg" "statusbar.url.fg" "tabs.odd.fg" "tabs.even.fg" "tabs.selected.even.bg" "tabs.selected.odd.bg" "tabs.pinned.selected.even.bg" "tabs.pinned.selected.odd.bg" "statusbar.url.success.http.fg" "statusbar.url.success.https.fg" ]
          (const base07)

        # Red.
        ) // (genAttrs [ "statusbar.url.error.fg" "statusbar.url.warn.fg" "tabs.indicator.error" ]
          (const base08)

        # Green.
        ) // (genAttrs []
          (const base0B)

        # Blue.
        ) // (genAttrs [ "statusbar.url.hover.fg"  "tabs.pinned.even.bg" "tabs.pinned.odd.bg" ]
          (const base0D)
        );

        session.lazy_restore        = true;
        auto_save.session           = true;
        content.autoplay            = false;
        input.insert_mode.auto_load = true;

        statusbar.widgets = [
          "progress"
          "keypress"
          "search_match"
          "url"
          "text:\:\:"
          "scroll"
          "text:\:\:"
          "history"
          "tabs"
          "text:\:\:"
          "clock"
          "text: "
        ];
      };

      aliases = {
        "bc" = "tab-close";
        "rl" = "reload";
        "bp" = "tab-prev";
        "bn" = "tab-next";
      };

      keyBindings.normal = {
        "d"        = "nop";
        "f"        = "nop";
        "gw"       = "hint";
        "K"        = "tab-prev";
        "J"        = "tab-next";
        "<Space>f" = "cmd-set-text -s :open -tr";
        "<Space>b" = "cmd-set-text -s :tab-select";
        "<Ctrl+s>" = "config-cycle tabs.show always never";
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
