# Credit to https://github.com/rgbcube/ncc for most of this.
{
  flake.modules.darwin.fixes = {
    system.defaults = {

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      menuExtraClock.Show24Hour = true;
      controlcenter = {
        Bluetooth = true;
        BatteryShowPercentage = true;
      };

      LaunchServices.LSQuarantine = false;

      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleTemperatureUnit = "Celsius";
        NSDocumentSaveNewDocumentsToCloud = false;
      };

      CustomSystemPreferences."com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
        allowIdentifierForAdvertising = false;
        forceLimitAdTracking = true;
        personalizedAdsMigrated = false;
      };

      CustomSystemPreferences."com.apple.dock" = {
        autohide-time-modifier = 0.0;
        autohide-delay = 0.0;
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

      dock = {
        autohide = true;
        showhidden = true;

        mouse-over-hilite-stack = true;

        show-recents = false;
        mru-spaces = false;

        tilesize = 48;
        magnification = false;

        enable-spring-load-actions-on-all-items = true;

        persistent-apps = [
          { app = "/Applications/Nix\ User\ Apps/Zed.app"; }
          { app = "/Applications/Nix\ User\ Apps/kitty.app"; }
        ];
      };
    };
    # FIXME: Doesn't work for some reason.
    hjem.extraModule = {
      files.".hushlogin".text = "";
    };
  };
}
