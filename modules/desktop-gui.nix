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

      # Color scheme for gsettings (prefer-dark, default, prefer-light)
      colorScheme = if theme.isDark then "prefer-dark" else "default";

      gtkCommon = # ini
        ''
          gtk-font-name=${theme.font.sans.name} ${toString theme.font.size.normal}
          gtk-theme-name=${theme.gtk.name}
          gtk-icon-theme-name=${theme.icons.name}
        '';

      gtk2 = # ini
        ''
          gtk-font-name="${theme.font.sans.name} ${toString theme.font.size.normal}"
          gtk-theme-name="${theme.gtk.name}"
          gtk-icon-theme-name="${theme.icons.name}"
        '';

      gtk3 = # ini
        ''
          [Settings]
          gtk-application-prefer-dark-theme=${if theme.isDark then "true" else "false"}
          ${gtkCommon}
        '';

      gtk4 = # ini
        ''
          [Settings]
          gtk-application-prefer-dark-theme=${if theme.isDark then "true" else "false"}
          gtk-interface-color-scheme=${if theme.isDark then "2" else "3"}
          ${gtkCommon}
        '';

    in
    {
      qt = {
        enable = true;

        style = config.theme.qt.name;
      };

      programs.dconf = {
        enable = true;

        profiles.user.databases = singleton {
          settings."org/gnome/desktop/interface".color-scheme = colorScheme;
        };
      };

      environment.systemPackages = [
        pkgs.bibata-cursors
      ];

      environment.sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "24";
      };

      hjem.extraModules = singleton {
        packages = singleton theme.gtk.package;

        files.".gtkrc-2.0".text = gtk2;
        xdg.config.files."gtk-3.0/settings.ini".text = gtk3;
        xdg.config.files."gtk-4.0/settings.ini".text = gtk4;

        # Disable rounded windows.
        xdg.config.files."gtk-3.0/gtk.css".text = # css
          ''
            window {
              border-radius: 0;
            }
          '';

        xdg.config.files."gtk-4.0/gtk.css".text = # css
          ''
            window {
              border-radius: 0;
            }
          '';
      };
    };

in
{
  flake.modules.nixos.desktop-gui = desktopGuiBase;
}
