{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf enabled;
in mkIf (config.isDesktopNotWsl && config.isGaming) {
  programs.steam = enabled {
    remotePlay.openFirewall                = true;
    dedicatedServer.openFirewall           = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable                = true;
  };

  # Performance.
  programs.gamemode = enabled {
    settings = {
      custom = {
        # Doesn't seem to work right now.
        start = "${pkgs.systemd}/bin/systemctl --user stop gammastep.service";
        end   = "${pkgs.systemd}/bin/systemctl --user start gammastep.service";
      };
    };
  };

  environment.systemPackages = [
    pkgs.protontricks
    pkgs.winetricks
  ];

  # Hardware acceleration and 32-bit graphics support.
  hardware.graphics = {
    enable      = true;
    enable32Bit = true; # Required for Steam and 32-bit games
  };


  # Audio settings for gaming
  security.rtkit.enable = true; # For low-latency audio
}
