{ lib, config, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktopNotWsl {
  home-manager.sharedModules = [{
    programs.foot = enabled {
      settings = {
        main = with config.theme.font; {
          font      = "${mono.name}:size=${toString size.term}";
          dpi-aware = "yes";
        };
        colors = with config.theme.colors; {
          background = base00;
          foreground = base05;
          urls       = base0D;

          regular0 = base00;
          regular1 = base08;
          regular2 = base0B;
          regular3 = base0A;
          regular4 = base0D;
          regular5 = base0E;
          regular6 = base0C;
          regular7 = base05;
        };
      };
    };
  }];
}
