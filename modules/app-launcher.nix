let
  fuzzelBase =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) theme;

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
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.fuzzel;

        xdg.config.files."fuzzel/fuzzel.ini".source = ini.generate "fuzzel.ini" settings;
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
  flake.modules.nixos.app-launcher = fuzzelBase;
  flake.modules.darwin.app-launcher = raycastBase;
}
