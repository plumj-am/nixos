{ self, ... }:
{
  flake.nixosModules.desktop = self.nixosModules.desktop-gui;
  flake.nixosModules.desktop-gui =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (config) theme;

      colorScheme = if theme.isDark then "'prefer-dark'" else "'prefer-light'";

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

      disabledRoundedWindows = # css
        ''
          window {
            border-radius: 0;
          }
        '';
    in
    {
      # Battery and power queries for desktop apps; the Canopy bar reads sysfs
      # itself, so this is not a shell dependency.
      services.upower.enable = true;

      qt = {
        enable = true;

        style = config.theme.qt.name;
        platformTheme = config.theme.qt.platformTheme;
      };

      programs.dconf = {
        enable = true;

        profiles.user.databases = singleton {
          settings."org/gnome/desktop/interface" = {
            font-name = theme.font.sans.name;
            color-scheme = colorScheme;
          };
        };
      };

      # dconf sends change signals only for the user database, so swapping the
      # generation's file-db does not reach running applications or the settings
      # portal. On a live switch, write the variant into the user database from
      # this per-user unit: the activation has already swapped the profile, so
      # the write passes and the service broadcasts it to consumers. A boot has
      # no session bus, so this step skips there; hjem's theme-dconf user unit
      # (see below) applies the variant when the session starts.
      systemd.services."hjem-activate@".postStart = ''
        uid=$(id --user)
        if [ -S "/run/user/$uid/bus" ]; then
          XDG_RUNTIME_DIR="/run/user/$uid" \
          DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
          ${getExe pkgs.dconf} write /org/gnome/desktop/interface/color-scheme "${colorScheme}" || true
        fi
      '';

      environment.systemPackages = [
        pkgs.bibata-cursors
      ];

      environment.sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "24";
      };

      hjemModule = {
        # The hjem-activate post-start hook covers live switches. A boot has
        # no session bus, so the stored variant can still be stale when the
        # session starts; this user unit rewrites it from the booted generation.
        systemd.services.theme-dconf = {
          description = "Write the theme variant into the user dconf database";
          wantedBy = singleton "default.target";
          after = singleton "dbus.socket";
          serviceConfig.Type = "oneshot";
          script = # bash
            ''
              if [ -n "$XDG_RUNTIME_DIR" ] && [ -S "$XDG_RUNTIME_DIR/bus" ]; then
                export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
              fi
              ${getExe pkgs.dconf} write /org/gnome/desktop/interface/color-scheme "${colorScheme}" || true
            '';
        };

        files.".gtkrc-2.0".text = gtk2;
        xdg.config.files."gtk-3.0/settings.ini".text = gtk3;
        xdg.config.files."gtk-4.0/settings.ini".text = gtk4;

        xdg.config.files."gtk-3.0/gtk.css".text = disabledRoundedWindows;
        xdg.config.files."gtk-4.0/gtk.css".text = disabledRoundedWindows;
      };
    };
}
