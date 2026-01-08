lib: {
  class  = "darwin";
  config = lib.darwinSystem' {
    system  = "aarch64-darwin";
    modules = [
      ({ self, ... }: {
        imports = [
          (self + /modules/system.nix)
          (self + /modules/nix.nix)
        ];

        type                        = "desktop";
        nixpkgs.hostPlatform.system = "aarch64-darwin";
        nixpkgs.config.allowUnfree  = true; # Only blanket allow is possible on nix-darwin.

        system = {
          primaryUser = "jam";

          # Thanks github/rgbcube for the stuff below.
          defaults.CustomSystemPreferences."com.apple.AdLib" = {
            allowApplePersonalizedAdvertising = false;
            allowIdentifierForAdvertising     = false;
            forceLimitAdTracking              = true;
            personalizedAdsMigrated           = false;
          };

          defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

          defaults.loginwindow = {
            DisableConsoleAccess = true;
            GuestEnabled         = false;
          };

          defaults.trackpad = {
            Clicking = false; # No touch-to-click.
            Dragging = false; # No tap-to-drag.
          };

          defaults.dock = {
            autohide   = true;
            showhidden = true; # Translucent.

            mouse-over-hilite-stack = true;

            show-recents = false;
            mru-spaces   = false;

            tilesize      = 48;
            magnification = false;

            enable-spring-load-actions-on-all-items = true;

            persistent-apps = [
              { app = "/Users/jam/Applications/Home Manager Apps/Alacritty.app"; }
              { app = "/Users/jam/Applications/Home Manager Apps/Arc.app"; }
              { app = "/Users/jam/Applications/Home Manager Apps/Karabiner-Elements.app"; }
            ];
          };

          defaults.CustomSystemPreferences."com.apple.dock" = {
            autohide-time-modifier    = 0.0;
            autohide-delay            = 0.0;
            expose-animation-duration = 0.0;
            springboard-show-duration = 0.0;
            springboard-hide-duration = 0.0;
            springboard-page-duration = 0.0;

            # Disable hot corners.
            wvous-tl-corner = 0;
            wvous-tr-corner = 0;
            wvous-bl-corner = 0;
            wvous-br-corner = 0;

            launchanim = 0;
          };
        };
        system.stateVersion = 5;
      })
    ];
  };
}
