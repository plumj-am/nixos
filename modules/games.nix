{
  flake.modules.nixos.games =
    { pkgs, config, ... }:
    let
      inherit (config.myLib) mkDesktopEntry;
      packages = [
        pkgs.steam
        pkgs.gamemode
        pkgs.protontricks
        pkgs.winetricks
      ];
    in
    {
      environment.systemPackages = packages ++ [
        (mkDesktopEntry { inherit pkgs; } {
          name = "Overwatch";
          exec = "steam steam://rungameid/2357570";
        })
      ];

      # Hardware acceleration and 32-bit graphics support.
      hardware.graphics = {
        enable = true;
        enable32Bit = true; # Required for Steam and 32-bit games
      };

      # Audio settings for gaming
      security.rtkit.enable = true; # For low-latency audio
    };
}
