# thanks github:rgbcube/ncc
{ lib, config, ... }: let
  inherit (lib) enabled mkIf;

  lockedAs = Value: attrs: attrs // {
    inherit Value;
    Locked = true;
  };

  locked = attrs: attrs // { Locked = true; };

  policies = {
    AutofillAddressEnabled    = false;
    AutofillCreditCardEnabled = false;
    AutofillPasswordEnabled   = false;

    DisableAppUpdate    = true;
    AppAutoUpdate       = false;
    BackgroundAppUpdate = false;

    DisableFeedbackCommands = true;
    DisableFirefoxStudies   = true;
    DisablePocket           = true;
    DisableTelemetry        = true;
    DisableProfileImport    = true;
    DisableProfileRefresh   = true;

    BlockAboutConfig   = false;
    BlockAboutProfiles = true;
    BlockAboutSupport  = true;

    DontCheckDefaultBrowser = false;

    NoDefaultBookmarks = true;

    SkipTermsOfUse = true;

    PictureInPicture = lockedAs true {};

    Homepage = locked { StartPage = "previous-session"; };

    EnableTrackingProtection = lockedAs true {
      Cryptomining   = true;
      EmailTracking  = true;
      Fingerprinting = true;
    };

    UserMessaging = locked {
      ExtensionRecommendations = false;
      FeatureRecommendations   = false;
      FirefoxLabs              = false;
      MoreFromMozilla          = false;
      SkipOnboarding           = true;
    };

    FirefoxSuggest = locked {
      ImproveSuggest       = false;
      SponsoredSuggestions = false;
      WebSuggestions       = false;
    };

    SearchEngines = {
      Default         = "Google";
      PreventInstalls = true;
    };

    # Can't get theme switching to work right now.
    # Actually none of this seems to work.
    Preferences = {
      "layout.css.prefers-color-scheme.content-override" = if config.theme.is_dark then 0 else 1;
      "devtools.theme" = if config.theme.is_dark then "dark" else "light";
      "zen.theme.accent-color" = "#${config.theme.colors.base09}";
      "zen.widget.linux.transparency" = "true";
      "zen.theme.gradient" = true;
      "zen.theme.gradient.show-custom-colors" = true;
      "zen.watermark.enabled" = false;
    };
  };
in {
  home-manager.sharedModules = [{
    programs.zen-browser = mkIf config.isDesktopNotWsl (enabled {
      inherit policies;
    });
  }];
}
