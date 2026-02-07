let
  ghosttyBase =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (pkgs.formats) keyValue;
      inherit (lib.attrsets) mapAttrsToList mapAttrs' nameValuePair;
      inherit (lib.lists) singleton;
      inherit (lib.generators) mkKeyValueDefault;
      inherit (config) theme;
      inherit (config.myLib) mkDesktopEntry;

      # Thank you to: <https://github.com/snugnug/hjem-rum/blob/main/modules/collection/programs/ghostty.nix>
      # for `mkTheme`.
      ghosttyKeyValue = keyValue {
        listsAsDuplicateKeys = true;
        mkKeyValue = mkKeyValueDefault { } " = ";
      };

      mkThemes =
        themes:
        mapAttrs' (
          name: value:
          nameValuePair "ghostty/themes/${name}" {
            source = ghosttyKeyValue.generate "ghostty-${name}-theme" value;
          }
        ) themes;

      settings = with theme; {
        font-size = font.size.normal;
        font-family = font.mono.name;
        font-feature = "+calt, +liga, +dlig";

        theme = if theme.colorScheme == "pywal" then "custom" else theme.ghostty;

        window-padding-x = padding.small;
        window-padding-y = padding.small;
        window-decoration = false;

        scrollback-limit = 100 * 1024 * 1024; # 100 MiB

        mouse-hide-while-typing = true;

        confirm-close-surface = false;
        quit-after-last-window-closed = true;

        keybind = mapAttrsToList (name: value: "ctrl+shift+${name}=${value}") {
          c = "copy_to_clipboard";
          v = "paste_from_clipboard";

          i = "inspector:toggle";

          plus = "increase_font_size:1";
          minus = "decrease_font_size:1";
          equal = "reset_font_size";
        };
      };

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
      hjem.extraModules = singleton {
        packages = [
          inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.ghostty

          (mkDesktopEntry { inherit pkgs; } {
            name = "Zellij-Ghostty";
            exec = "ghostty -e ${pkgs.zellij}/bin/zellij";
          })
        ];

        xdg.config.files = {
          "ghostty/config".source = ghosttyKeyValue.generate "ghostty-config" settings;
        }
        // mkThemes themes;
      };
    };
in
{
  flake-file.inputs = {
    ghostty = {
      url = "github:ghostty-org/ghostty";

      inputs.nixpkgs.follows = "os";
    };
  };

  flake.modules.nixos.ghostty = ghosttyBase;
  flake.modules.darwin.ghostty = ghosttyBase;
}
