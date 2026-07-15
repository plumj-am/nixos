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
      environment.sessionVariables = {
        PROTON_ENABLE_WAYLAND = "1";

        # maybe these only works in steam launch options?
        PROTON_LOCAL_SHADER_CACHE = "1";
        __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
        __GL_SHADER_DISK_CACHE_SIZE = "21474836480";
        DXVK_CONFIG = "dxvk.trackPipelineLifetime = True";
      };

      environment.systemPackages = packages ++ [
        (mkDesktopEntry {
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
