{
  flake.modules.nixos.desktop-gui =
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

  flake.modules.hjem.desktop-gui =
    {
      lib,
      theme,
      isDesktop,
      isLinux,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.lists) singleton;

      settingsGtk3 = # ini
        ''
          [Settings]
          gtk-prefer-dark=${toString theme.isDark}
          gtk-font-name=${theme.font.sans.name} ${toString theme.font.size.normal}
          gtk-theme-name=${theme.gtk.name}
          gtk-icon-theme-name=${theme.icons.name}
        '';

      settingsGtk2 = # ini
        ''
          gtk-prefer-dark=${toString theme.isDark}
          gtk-font-name=${theme.font.sans.name} ${toString theme.font.size.normal}
          gtk-theme-name=${theme.gtk.name}
          gtk-icon-theme-name=${theme.icons.name}
        '';

    in
    mkIf (isDesktop && isLinux) {
      packages = singleton theme.gtk.package;

      files.".gtkrc-2.0".text = settingsGtk2;
      xdg.config.files."gtk-3.0/settings.ini".text = settingsGtk3;
      xdg.config.files."gtk-4.0/settings.ini".text = settingsGtk3;
    };
}
