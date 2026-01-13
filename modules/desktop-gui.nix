{
  config.flake.modules.nixos.desktop-gui =
    { pkgs, config, ... }:
    {
      qt = {
        enable = true;

        style = config.theme.qt.name;
      };

      programs.dconf.enable = true;

      environment.systemPackages = [
        pkgs.bibata-cursors
      ];

      environment.sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "24";
      };
    };

  config.flake.modules.hjem.desktop-gui =
    { theme, ... }:
    let
      packages = [ theme.gtk.package ];
    in
    {
      rum.misc.gtk = {
        inherit packages;
        enable = true;
        settings = {
          font-name = "${theme.font.sans.name} ${toString theme.font.size.small}";
          theme-name = theme.gtk.name;
          icon-theme-name = theme.icons.name;
        };
      };
    };
}
