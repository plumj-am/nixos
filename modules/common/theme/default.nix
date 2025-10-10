{ lib, config, ... }:
let
  inherit (lib) mkOption types mkIf enabled;
in
{
  imports = lib.collectNix ./.
    |> lib.remove ./default.nix;

  # Define theme as a top-level option that all modules can access via config.theme.
  options.theme = mkOption {
    type        = types.attrs;
    default     = {};
    description = "Global theme configuration";
  };

  config = mkIf config.isDesktop {
    theme = {
    # Shared design system.
    radius = {
      small    = 2;
      normal   = 4;
      big      = 6;
      verybig  = 8;
    };

    border  = {
      small  = 2;
      normal = 4;
      big    = 6;
    };

    margin = {
      small  = 4;
      normal = 8;
      big    = 32;
    };

    padding = {
      small  = 4;
      normal = 8;
    };

    opacity = {
      opaque   = 1.00;
      veryhigh = 0.98;
      high     = 0.97;
      medium   = 0.94;
      low      = 0.90;
      verylow  = 0.80;
    };

    duration = {
      s = {
        short  = 0.5;
        normal = 1.0;
        long   = 1.5;
      };
      ms = {
        short  = 150;
        normal = 200;
        long   = 300;
      };
    };
    };

    home-manager.sharedModules = mkIf config.isDesktopNotWsl [
      (homeArgs: {
        programs.pywal = enabled;

        xdg.desktopEntries.dark-mode = {
          name     = "Dark Mode";
          icon     = "preferences-color-symbolic";
          exec     = ''tt dark'';
          terminal = false;
        };
        xdg.desktopEntries.light-mode = {
          name     = "Light Mode";
          icon     = "preferences-color-symbolic";
          exec     = ''tt light'';
          terminal = false;
        };
        xdg.desktopEntries.pywal-mode = {
          name     = "Pywal Mode";
          icon     = "preferences-color-symbolic";
          exec     = ''tt pywal'';
          terminal = false;
        };
        xdg.desktopEntries.gruvbox-mode = {
          name     = "Gruvbox Mode";
          icon     = "preferences-color-symbolic";
          exec     = ''tt gruvbox'';
          terminal = false;
        };
      })
    ];
  };
}
