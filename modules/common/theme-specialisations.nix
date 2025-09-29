{ config, lib, ... }: let
  inherit (lib) mkIf;
in {
  config = mkIf config.isDesktopNotWsl {
    # Specialisations for system-level theme switching.
    specialisation = {
      dark-theme = {
        configuration = {

          # Force dark theme.
          themeOverride = lib.mkForce true;

          # For identification.
          system.nixos.tags = [ "dark-theme" ];

          # Include the light theme specialisation in dark theme.
          specialisation.light-theme = {
            configuration = {
              themeOverride = lib.mkForce false;
              system.nixos.tags = [ "light-theme" ];
            };
          };
        };
      };

      # Light theme specialisation.
      light-theme = {
        configuration = {
          # Force light theme.
          themeOverride = lib.mkForce false;

          # For identification.
          system.nixos.tags = [ "light-theme" ];

          # Include the dark theme specialisation in light theme.
          specialisation.dark-theme = {
            configuration = {
              themeOverride = lib.mkForce true;
              system.nixos.tags = [ "dark-theme" ];
            };
          };
        };
      };
    };

    # Home Manager specialisations for user-level theme switching.
    home-manager.sharedModules = [{
      specialisation = {
        dark = {
          configuration = {
            # Override theme to dark in home-manager.
            home.sessionVariables.THEME_MODE = "dark";
          };
        };
        light = {
          configuration = {
            # Override theme to light in home-manager.
            home.sessionVariables.THEME_MODE = "light";
          };
        };
      };
    }];
  };
}
