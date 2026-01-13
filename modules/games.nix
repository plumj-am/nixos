{
  flake.modules.nixos.games =
    { pkgs, ... }:
    let
      packages = [
        pkgs.steam
        pkgs.gamemode
        pkgs.protontricks
        pkgs.winetricks
      ];
    in
    {
      environment.systemPackages = packages ++ [
        (pkgs.writeTextFile {
          name = "overwatch";
          destination = "/share/applications/overwatch.desktop";
          text = ''
            [Desktop Entry]
            Name=Overwatch
            Icon=Overwatch
            Exec=steam steam://rungameid/2357570
            Terminal=false
          '';
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
