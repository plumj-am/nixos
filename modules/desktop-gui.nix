let
  desktopGuiBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) theme;

      commonGtk = # ini
        ''
          gtk-prefer-dark=${toString theme.isDark}
          gtk-font-name=${theme.font.sans.name} ${toString theme.font.size.normal}
          gtk-theme-name=${theme.gtk.name}
          gtk-icon-theme-name=${theme.icons.name}
        '';

      settingsGtk2 = commonGtk;

      settingsGtk3 = # ini
        ''
          [Settings]
          ${commonGtk}
        '';

    in
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

      hjem.extraModules = singleton {
        packages = singleton theme.gtk.package;

        files.".gtkrc-2.0".text = settingsGtk2;
        xdg.config.files."gtk-3.0/settings.ini".text = settingsGtk3;
        xdg.config.files."gtk-4.0/settings.ini".text = settingsGtk3;

        # Disable rounded corners in GTK
        xdg.config.files."gtk-3.0/gtk.css".text = # css
          ''
            * {
              border-radius: 0;
            }
          '';
        xdg.config.files."gtk-4.0/gtk.css".text = # css
          ''
            * {
              border-radius: 0;
            }
          '';
      };
    };

in
{
  flake.modules.nixos.desktop-gui = desktopGuiBase;
}
