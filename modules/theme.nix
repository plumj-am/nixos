{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.attrsets) mapAttrs listToAttrs elemAt;
  inherit (lib.trivial) fromHexString;
  inherit (lib.types) attrs;
  inherit (lib.lists) genList;
  inherit (lib)
    fromJSON
    readFile
    substring
    pathExists
    ;

  # Shared theme configuration logic
  mkThemeConfig =
    { pkgs }:
    let
      themeConfig = fromJSON (readFile ./theme.json);
      isDark = themeConfig.mode == "dark";
      colorScheme = themeConfig.scheme;

      pywalCache = ./theme-pywal-colors.json;

      parsePywalColors =
        json:
        let
          colors = fromJSON json;
          stripHash = s: substring 1 6 s;
          colorNames = [
            "base00"
            "base01"
            "base02"
            "base03"
            "base04"
            "base05"
            "base06"
            "base07"
            "base08"
            "base09"
            "base0A"
            "base0B"
            "base0C"
            "base0D"
            "base0E"
            "base0F"
          ];
        in
        listToAttrs (
          genList (n: {
            name = elemAt colorNames n;
            value = stripHash (elemAt colors.colors.colors n);
          }) 16
        );

      pywalColors =
        if pathExists pywalCache then parsePywalColors (readFile pywalCache) else gruvboxColors.dark;

      gruvboxColors = {
        dark = {
          base00 = "1d2021";
          base01 = "3c3836";
          base02 = "504945";
          base03 = "665c54";
          base04 = "bdae93";
          base05 = "d5c4a1";
          base06 = "ebdbb2";
          base07 = "fbf1c7";
          base08 = "fb4934";
          base09 = "fe8019";
          base0A = "fabd2f";
          base0B = "b8bb26";
          base0C = "8ec07c";
          base0D = "83a598";
          base0E = "d3869b";
          base0F = "d65d0e";
        };
        light = {
          base00 = "f9f5d7";
          base01 = "ebdbb2";
          base02 = "d5c4a1";
          base03 = "bdae93";
          base04 = "665c54";
          base05 = "504945";
          base06 = "3c3836";
          base07 = "282828";
          base08 = "9d0006";
          base09 = "af3a03";
          base0A = "b57614";
          base0B = "79740e";
          base0C = "427b58";
          base0D = "076678";
          base0E = "8f3f71";
          base0F = "d65d0e";
        };
      };

      colors =
        if colorScheme == "pywal" then
          pywalColors
        else
          (if isDark then gruvboxColors.dark else gruvboxColors.light);

      variant = if isDark then "dark" else "light";

      hexToRgb =
        hex:
        let
          r = fromHexString (substring 0 2 hex);
          g = fromHexString (substring 2 2 hex);
          b = fromHexString (substring 4 2 hex);
        in
        [
          r
          g
          b
        ];

      designSystem = {
        font = {
          size.tiny = 9;
          size.small = 10;
          size.normal = 12;
          size.big = 16;

          mono.name = "Maple Mono NF";
          mono.family = "Maple Mono";
          mono.package = pkgs.maple-mono.NF;

          sans.name = "Lexend";
          sans.family = "Lexend";
          sans.package = pkgs.lexend;
        };

        radius = {
          tiny = 1;
          small = 2;
          normal = 4;
          big = 8;
        };

        border = {
          small = 2;
          normal = 4;
        };

        margin = {
          small = 4;
          normal = 8;
        };

        padding = {
          small = 4;
          normal = 8;
        };
      };

      themes = {
        alacritty.dark = "gruvbox_material_hard_dark";
        alacritty.light = "gruvbox_material_hard_light";

        ghostty.dark = "Gruvbox Dark Hard";
        ghostty.light = "Gruvbox Light Hard";

        rio.dark = "gruvbox-dark-hard";
        rio.light = "gruvbox-light-hard";

        zellij.dark = "gruvbox-dark";
        zellij.light = "gruvbox-light";

        starship.dark = "dark_theme";
        starship.light = "light_theme";

        vivid.dark = "gruvbox-dark";
        vivid.light = "gruvbox-light";

        nushell.dark = "dark-theme";
        nushell.light = "light-theme";

        helix.dark = "gruvbox_dark_hard";
        helix.light = "gruvbox_light_hard";

        bat.dark = "gruvbox-dark";
        bat.light = "gruvbox-light";

        gtk.dark = {
          name = "Gruvbox-Dark";
          package = pkgs.gruvbox-gtk-theme;
        };
        gtk.light = {
          name = "Adwaita";
          package = pkgs.gnome-themes-extra;
        };

        qt.dark = {
          name = "adwaita-dark";
          platformTheme = "adwaita";
        };
        qt.light = {
          name = "adwaita";
          platformTheme = "adwaita";
        };

        icons.dark = {
          name = "Gruvbox-Plus-Dark";
          package = pkgs.gruvbox-plus-icons;
        };
        icons.light = {
          name = "Papirus-Light";
          package = pkgs.papirus-icon-theme;
        };
      };

      getTheme = program: if isDark then themes.${program}.dark else themes.${program}.light;
    in
    {
      inherit
        isDark
        colorScheme
        variant
        colors
        designSystem
        themes
        getTheme
        hexToRgb
        ;
    };

  # Shared theme module configuration (used by both nixos and darwin)
  themeBase =
    { pkgs, ... }:
    let
      theme = mkThemeConfig { inherit pkgs; };
      themedApps = [
        "icons"
        "alacritty"
        "ghostty"
        "rio"
        "zellij"
        "starship"
        "vivid"
        "nushell"
        "helix"
        "bat"
        "gtk"
        "qt"
      ];
    in
    {
      options.theme = mkOption {
        type = attrs;
        default = { };
        description = "Global theme configuration";
      };

      config = {
        theme =
          theme.designSystem
          // {
            inherit (theme)
              themes
              isDark
              colorScheme
              variant
              colors
              ;

            withHash = mapAttrs (_: v: "#${v}") theme.colors;
            with0x = mapAttrs (_: v: "0x${v}") theme.colors;
            withRgb = mapAttrs (_: v: theme.hexToRgb v) theme.colors;
          }
          // (listToAttrs (
            map (app: {
              name = app;
              value = theme.getTheme app;
            }) themedApps
          ));
      };
    };

  themeExtraFonts =
    { config, pkgs, ... }:
    {
      console = {
        earlySetup = true;
        font = "Lat2-Terminus16";
        packages = [ pkgs.terminus_font ];
      };

      fonts.fontconfig.enable = true;

      fonts.packages = [
        config.theme.font.mono.package
        config.theme.font.sans.package
        pkgs.noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-lgc-plus
        pkgs.noto-fonts-color-emoji
      ];
    };

  themeExtraScripts =
    { config, pkgs, ... }:
    let
      inherit (lib) map;
      inherit (config.myLib) mkDesktopEntry;

      pickWallpaper = pkgs.writeScriptBin "pick-wallpaper" (readFile ./nushell.pick-wallpaper.nu);

      themeToggleScript = pkgs.writeScriptBin "tt" (readFile ./nushell.toggle-theme.nu);
    in
    {
      environment.systemPackages = [
        pkgs.swww
        themeToggleScript
        pickWallpaper
      ]
      ++ (map (mkDesktopEntry { inherit pkgs; }) [
        {
          name = "Dark-Mode";
          exec = "tt dark";
        }
        {
          name = "Light-Mode";
          exec = "tt light";
        }
        {
          name = "Pywal-Mode";
          exec = "tt pywal";
        }
        {
          name = "Gruvbox-Mode";
          exec = "tt gruvbox";
        }
        {
          name = "Reload-Applications";
          exec = "tt reload";
        }
        {
          name = "Pick-Wallpaper";
          exec = "pick-wallpaper";
          terminal = true;
        }
      ]);
    };
in
{
  flake.modules.darwin.theme = themeBase;
  flake.modules.nixos.theme = themeBase;

  flake.modules.nixos.theme-extra-fonts = themeExtraFonts;
  flake.modules.nixos.theme-extra-scripts = themeExtraScripts;
}
