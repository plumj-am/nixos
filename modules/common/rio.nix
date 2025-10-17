{ pkgs, config, lib, inputs, ... }: let
  inherit (lib) enabled mkIf genAttrs const merge;
in {
  # This isn't working for now. Not sure why and can't find a related issue.
  # After loading I can't do anything and debug logs are full of: `[unhandled osc_dispatch]`.
  home-manager.sharedModules = mkIf config.isDesktopNotWsl [{
    programs.rio = with config.theme; enabled {
      package = inputs.rio.packages.${pkgs.stdenv.hostPlatform.system}.rio;

      themes = {
        gruvbox-dark-hard.colors = {
          background           = "#1d2021";
          foreground           = "#ebdbb2";
          selection-background = "#665c54";
          selection-foreground = "#ebdbb2";
          cursor               = "#ebdbb2";
          black                = "#1d2021";
          red                  = "#cc241d";
          green                = "#98971a";
          yellow               = "#d79921";
          blue                 = "#458588";
          magenta              = "#b16286";
          cyan                 = "#689d6a";
          white                = "#a89984";
          light_black          = "#928374";
          light_red            = "#fb4934";
          light_green          = "#b8bb26";
          light_yellow         = "#fabd2f";
          light_blue           = "#83a598";
          light_magenta        = "#d3869b";
          light_cyan           = "#8ec07c";
          light_white          = "#ebdbb2";
        };

        gruvbox-light-hard.colors = {
          background           = "#f9f5d7";
          foreground           = "#3c3836";
          selection-background = "#3c3836";
          selection-foreground = "#f9f5d7";
          cursor               = "#3c3836";
          black                = "#f9f5d7";
          red                  = "#cc241d";
          green                = "#98971a";
          yellow               = "#d79921";
          blue                 = "#458588";
          magenta              = "#b16286";
          cyan                 = "#689d6a";
          white                = "#7c6f64";
          light_black          = "#928374";
          light_red            = "#9d0006";
          light_green          = "#79740e";
          light_yellow         = "#b57614";
          light_blue           = "#076678";
          light_magenta        = "#8f3f71";
          light_cyan           = "#427b58";
          light_white          = "#3c3836";
        };
      };
      settings = {
        theme = config.theme.rio;
        editor.program = "hx";
        confirm-before-quit = false;
        hide-mouse-cursor-when-typing = true;
        navigation.use-split = false;
        padding-x = padding.small;
        padding-y = [ padding.small padding.small ];

        shell.program = lib.getExe pkgs.nushell;
        shell.args    = [ "--login" "--interactive" ];

        renderer = {
          disable-unfocused-render = true;
          target-fps = 280;
        };

        window.decorations = "Disabled";

        fonts = merge {
          size               = font.size.big;
          features           = [];
          use-drawable-chars = true;

          emoji.family = "Noto Color Emoji";
        } <| genAttrs [ "regular" "bold" "italic" "bold-italic" ] (const {
          family = font.mono.name;
          width  = "Normal";
        });
      };
    };

    xdg.desktopEntries.zellij-rio = {
      name     = "Zellij Rio";
      icon     = "rio";
      exec     = "rio --command ${pkgs.zellij}/bin/zellij";
      terminal = false;
    };
  }];
}
