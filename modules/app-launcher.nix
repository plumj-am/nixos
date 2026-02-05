{
  flake.modules.hjem.app-launcher =
    {
      pkgs,
      theme,
      lib,
      isDesktop,
      isLinux,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.lists) singleton;

      settings = with theme; {
        main = {
          icon-theme = icons.name;
          font = "${font.sans.name}:size=${toString font.size.normal}";
          layer = "overlay";
          prompt = ''"❯ "'';
          terminal = "kitty";

          horizontal-pad = padding.small;
          vertical-pad = padding.small;
        };

        colors = {
          background = colors.base00 + "FF";
          text = colors.base07 + "FF";
          match = colors.base0A + "FF";
          selection = colors.base0A + "88"; # Lower opacity.
          selection-text = colors.base07 + "FF";
          selection-match = colors.base08 + "FF";
          border = colors.base0A + "FF";
        };

        border = {
          radius = radius.big;
          width = border.small;
        };
      };

      ini = pkgs.formats.ini { };
    in
    mkIf (isDesktop && isLinux) {
      packages = singleton pkgs.fuzzel;

      xdg.config.files."fuzzel/fuzzel.ini".source = ini.generate "fuzzel.ini" settings;
    };

  flake.modules.darwin.app-launcher =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.raycast
      ];
    };
}
