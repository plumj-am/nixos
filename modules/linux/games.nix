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
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    protontricks
    winetricks
  ];

  # Hardware acceleration and 32-bit graphics support.
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam and 32-bit games
  };


  # Audio settings for gaming
  security.rtkit.enable = true; # For low-latency audio
}
