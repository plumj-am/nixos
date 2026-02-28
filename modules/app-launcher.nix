let
  # fuzzelBase =
  #   {
  #     pkgs,
  #     config,
  #     lib,
  #     ...
  #   }:
  #   let
  #     inherit (lib.lists) singleton;
  #     inherit (config) theme;

  #     settings = with theme; {
  #       main = {
  #         icon-theme = icons.name;
  #         font = "${font.sans.name}:size=${toString font.size.normal}";
  #         layer = "overlay";
  #         prompt = ''"❯ "'';
  #         terminal = "kitty";

  #         horizontal-pad = padding.small;
  #         vertical-pad = padding.small;
  #       };

  #       colors = {
  #         background = colors.base00 + "FF";
  #         text = colors.base07 + "FF";
  #         match = colors.base0A + "FF";
  #         selection = colors.base0A + "88"; # Lower opacity.
  #         selection-text = colors.base07 + "FF";
  #         selection-match = colors.base08 + "FF";
  #         border = colors.base0A + "FF";
  #       };

  #       border = {
  #         radius = radius.big;
  #         width = border.small;
  #       };
  #     };

  #     ini = pkgs.formats.ini { };
  #   in
  #   {
  #     hjem.extraModules = singleton {
  #       packages = singleton pkgs.fuzzel;

  #       xdg.config.files."fuzzel/fuzzel.ini".source = ini.generate "fuzzel.ini" settings;
  #     };
  #   };

  tofiBase =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (pkgs.formats) keyValue;
      inherit (lib.generators) mkKeyValueDefault;
      inherit (config) theme;

      tofiKeyValue = keyValue {
        listsAsDuplicateKeys = true;
        mkKeyValue = mkKeyValueDefault { } " = ";
      };

      settings = with theme; {
        width = "50%";
        height = 26;
        anchor = "top-left";

        font = "${font.sans.package}/share/fonts/truetype/lexend/lexend/Lexend-Medium.ttf";
        font-size = font.size.small;
        hint-font = false;
        ascii-input = true;

        horizontal = true;
        num-results = 20;
        drun-launch = false;
        hide-input = true;
        hidden-character = ''""'';
        prompt-text = "[run]";

        outline-width = 0;
        border-width = 0;
        result-spacing = margin.normal * 2;
        padding-top = 4;
        padding-bottom = 0;
        padding-left = 10;
        padding-right = 0;

        background-color = theme.withHash.base00;
        prompt-color = theme.withHash.base06;
        text-color = theme.withHash.base04;
        selection-color = theme.withHash.base08;
      };
    in
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.tofi;

        xdg.config.files."tofi/config".source = tofiKeyValue.generate "tofi-config" settings;
      };
    };

  raycastBase =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.raycast
      ];
    };

in
{
  flake.modules.nixos.app-launcher = tofiBase;
  flake.modules.darwin.app-launcher = raycastBase;
}
