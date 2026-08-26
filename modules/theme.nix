{ self, lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.attrsets)
    mapAttrs
    genAttrs
    collect
    isDerivation
    ;
  inherit (lib.lists) elem;
  inherit (lib.trivial) fromHexString;
  inherit (lib.types) attrsOf anything;
  inherit (lib.strings)
    fromJSON
    readFile
    substring
    pathExists
    ;

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

  mkThemeConfig =
    { pkgs }:
    let
      themeConfig = fromJSON <| readFile ./theme.json;
      variant = themeConfig.mode;
      isDark = variant == "dark";
      colorScheme = themeConfig.scheme;

      # assert lib.elem variant ["light" "dark"];

      matugenCache = ./theme-matugen-colors.json;

      parseMatugenColors =
        json: mapAttrs (_: value: substring 1 6 value.${variant}.color) <| (fromJSON json).base16;

      matugenColors =
        if pathExists matugenCache then
          parseMatugenColors <| readFile matugenCache
        else
          gruvboxColors.${variant};

      colors = if colorScheme == "matugen" then matugenColors else gruvboxColors.${variant};

      hexToRgb =
        hex:
        let
          r = fromHexString <| substring 0 2 hex;
          g = fromHexString <| substring 2 2 hex;
          b = fromHexString <| substring 4 2 hex;
        in
        [
          r
          g
          b
        ];

      fonts = {
        mono = {
          iosevka = {
            name = "Iosevka Nerd Font Mono";
            family = "Iosevka";
            package = pkgs.nerd-fonts.iosevka;
          };
          maple-mono = {
            name = "Maple Mono NF";
            family = "Maple Mono";
            package = pkgs.maple-mono.NF;
          };
          hasklug = {
            name = "Hasklug Nerd Font Mono";
            family = "Hasklug";
            package = pkgs.nerd-fonts.hasklug;
          };
          fira-code = {
            name = "Fira Code Nerd Font Mono";
            family = "Fira Code";
            package = pkgs.nerd-fonts.fira-code;
          };
        };
        sans = {
          lexend = {
            name = "Lexend";
            family = "Lexend";
            package = pkgs.lexend;
          };
        };
      };

      designSystem = {
        font = {
          size = {
            tiny = 9;
            small = 10;
            normal = 12;
            medium = 14;
            big = 16;
          };

          mono = fonts.mono.maple-mono;
          sans = fonts.sans.lexend;
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
          tiny = 2;
          small = 4;
          normal = 8;
        };
      };

      apps = {

        rio = {
          dark = "gruvbox-dark-hard";
          light = "gruvbox-light-hard";
        };

        zellij = {
          dark = "gruvbox-dark";
          light = "gruvbox-light";
        };

        vivid = {
          dark = "gruvbox-dark";
          light = "gruvbox-light";
        };

        nushell = {
          dark = "dark-theme";
          light = "light-theme";
        };

        helix = {
          dark = "gruvbox_dark_hard";
          light = "gruvbox_light_hard";
        };

        bat = {
          dark = "gruvbox-dark";
          light = "gruvbox-light";
        };

        gtk = {
          dark = {
            name = "Gruvbox-Dark";
            package = pkgs.gruvbox-dark-gtk;
          };
          light = {
            name = "Adwaita";
            package = pkgs.gnome-themes-extra;
          };
        };

        qt = {
          dark = {
            name = "adwaita-dark";
            platformTheme = "gnome";
          };
          light = {
            name = "adwaita";
            platformTheme = "gnome";
          };
        };

        icons = {
          dark = {
            name = "Gruvbox-Plus-Dark";
            package = pkgs.gruvbox-plus-icons;
          };
          light = {
            name = "Papirus-Light";
            package = pkgs.papirus-icon-theme;
          };
        };
      };

      getAppTheme = program: apps.${program}.${variant};
    in
    assert elem variant [
      "dark"
      "light"
    ];
    assert elem colorScheme [
      "gruvbox"
      "matugen"
    ];
    {
      inherit
        isDark
        colorScheme
        variant
        colors
        designSystem
        apps
        getAppTheme
        hexToRgb
        ;
    };
in
{
  flake.modules.common.default = self.modules.common.theme;
  flake.modules.common.theme =
    { pkgs, ... }:
    let
      theme = mkThemeConfig { inherit pkgs; };
      themedApps = [
        "icons"
        "rio"
        "zellij"
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
        type = attrsOf anything;
        default = { };
        description = "Global theme configuration";
      };

      config = {
        # makes switching variants faster if they are all present
        environment.systemPackages = collect isDerivation theme.apps;

        theme =
          theme.designSystem
          // {
            inherit (theme)
              apps
              isDark
              colorScheme
              variant
              colors
              ;

            withHash = mapAttrs (_: v: "#${v}") theme.colors;
            with0x = mapAttrs (_: v: "0x${v}") theme.colors;
            withRgb = mapAttrs (_: v: theme.hexToRgb v) theme.colors;
          }
          // genAttrs themedApps theme.getAppTheme;
      };
    };

  flake.modules.nixos.theme-extra-fonts =
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
        pkgs.nerd-fonts.symbols-only
        pkgs.noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-lgc-plus
        pkgs.noto-fonts-color-emoji
      ];
    };

  flake.modules.darwin.default = self.modules.darwin.theme-extra-fonts;
  flake.modules.darwin.theme-extra-fonts =
    { config, pkgs, ... }:
    {
      fonts.packages = [
        config.theme.font.mono.package
        config.theme.font.sans.package
        pkgs.noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-lgc-plus
        pkgs.noto-fonts-color-emoji
      ];
    };

  flake.modules.nixos.theme-extra-scripts =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.awww
        pkgs.matugen
        self.packages.${pkgs.stdenv.hostPlatform.system}.toggle-theme
        self.packages.${pkgs.stdenv.hostPlatform.system}.pick-wallpaper
      ];
    };
}
