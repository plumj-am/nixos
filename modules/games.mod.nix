{
  config.flake.modules.nixosModules.games =
    { pkgs, ... }:
    let
      packages = [
        pkgs.steam
        pkgs.gamemode
        pkgs.protontricks
        pkgs.winetricks
      ];
    in {
      environment.systemPackages = packages;


      # Hardware acceleration and 32-bit graphics support.
      hardware.graphics = {
        enable      = true;
        enable32Bit = true; # Required for Steam and 32-bit games
      };


      # Audio settings for gaming
      security.rtkit.enable = true; # For low-latency audio

      # TODO: fix
      # xdg.desktopEntries.overwatch = {
      #   name     = "Overwatch";
      #   icon     = "com.valvesoftware.Steam";
      #   exec     = "steam steam://rungameid/2357570";
      #   terminal = false;
      # };
    };
}
