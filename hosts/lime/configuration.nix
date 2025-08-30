{
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "arc-browser-1.106.0-66192"
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      interval = {
        Weekday = 1;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 7d";
    };
  };

  users.users.james = {
    name = "james";
    home = "/Users/james";
    shell = pkgs.nushell;
  };

  system.primaryUser = "james";

  # thanks github/rgbcube for the stuff below
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
  };

  system.defaults.CustomSystemPreferences."com.apple.AdLib" = {
    allowApplePersonalizedAdvertising = false;
    allowIdentifierForAdvertising = false;
    forceLimitAdTracking = true;
    personalizedAdsMigrated = false;
  };

  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

  system.defaults.loginwindow = {
    DisableConsoleAccess = true;
    GuestEnabled = false;
  };

  system.defaults.trackpad = {
    Clicking = false; # no touch-to-click
    Dragging = false; # no tap-to-drag
  };

  system.defaults.dock = {
    autohide = true;
    showhidden = true; # translucent

    mouse-over-hilite-stack = true;

    show-recents = false;
    mru-spaces = false;

    tilesize = 48;
    magnification = false;

    enable-spring-load-actions-on-all-items = true;

    persistent-apps = [
      { app = "/Users/james/Applications/Home Manager Apps/Alacritty.app"; }
      { app = "/Users/james/Applications/Home Manager Apps/Arc.app"; }
      {
        app = "/Users/james/Applications/Home Manager Apps/Karabiner-Elements.app";
      }
    ];
  };

  system.defaults.CustomSystemPreferences."com.apple.dock" = {
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

  system.stateVersion = 5;
}
