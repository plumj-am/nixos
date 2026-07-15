{
  flake.modules.nixos.games =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.trivial) floor;
      inherit (config.myLib) mkDesktopEntry;
    in
    {
      environment.sessionVariables = {
        PROTON_ENABLE_WAYLAND = "1";
        __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
        __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
      };

      environment.systemPackages =
        singleton
        <| mkDesktopEntry {
          name = "Overwatch";
          exec = "steam steam://rungameid/2357570";
        };

      programs.steam = {
        enable = true;
        protontricks.enable = true;
        extraCompatPackages = singleton pkgs.proton-ge-bin;
        extraPackages = singleton pkgs.winetricks;
      };

      # Hardware acceleration and 32-bit graphics support.
      hardware.graphics = {
        enable = true;
        enable32Bit = true; # Required for Steam and 32-bit games
      };

      # Audio settings for gaming
      security.rtkit.enable = true; # For low-latency audio

      hjemModule.xdg.data.files."Steam/steam_dev.cfg".text = # cfg
        ''
          unShaderBackgroundProcessingThreads ${toString <| floor <| config.systemInfo.threads * 0.8}
        '';
    };
}
