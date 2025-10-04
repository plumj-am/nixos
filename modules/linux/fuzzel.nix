{ config, lib, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {

  home-manager.sharedModules = [{
    services.cliphist = enabled {
      extraOptions = [ "-max-items" "1000" ];
    };

    programs.fuzzel = with config.theme; enabled {
      settings.main = {
        icon-theme = icons.name;
        font       = "${font.mono.name}:size=${toString font.size.small}";
        layer      = "overlay";
        prompt     = ''"❯ "'';
        terminal   = "kitty";
        output     = mkIf (config.networking.hostName == "yuzu") "DP-1";

        horizontal-pad = padding;
        vertical-pad   = padding;
      };

      settings.colors = {
        background      = colors.base00 + "D9"; # 85% opacity.
        text            = colors.base07 + "FF";
        match           = colors.base0A + "FF"; # Yellow.
        selection       = colors.base02 + "FF";
        selection-text  = colors.base07 + "FF";
        selection-match = colors.base08 + "FF"; # Red.
        border          = colors.base0A + "FF"; # Yellow.
      };

      settings.border = {
        radius = radius;
        width  = border / 2;
      };
    };
  }];
}
