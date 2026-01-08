{
  config.flake.modules.homeModules.fuzzel =
    { config, ... }:
    {
      programs.fuzzel = with config.theme; {
        enable = true;

        settings.main = {
          icon-theme = icons.name;
          font = "${font.sans.name}:size=${toString font.size.small}";
          layer = "overlay";
          prompt = ''"❯ "'';
          terminal = "kitty";
          # output     = mkIf (config.networking.hostName == "yuzu") "DP-1";

          horizontal-pad = padding.normal;
          vertical-pad = padding.normal;
        };

        settings.colors = {
          background = colors.base00 + "FF";
          text = colors.base07 + "FF";
          match = colors.base0A + "FF";
          selection = colors.base0A + "88"; # Lower opacity.
          selection-text = colors.base07 + "FF";
          selection-match = colors.base08 + "FF";
          border = colors.base0A + "FF";
        };

        settings.border = {
          radius = radius.verybig;
          width = border.small;
        };
      };
    };
}
