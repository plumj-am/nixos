{
  flake.modules.nixos.games =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.trivial) floor;

      inherit (config.users.users.jam) home;
    in
    {
      imports = singleton inputs.steam-config.nixosModules.default;

      environment.sessionVariables = {
        PROTON_ENABLE_WAYLAND = "1";
        DVXK_HUD = "compiler";

        PROTON_LOCAL_SHADER_CACHE = "1";
        __GL_SHADER_DISK_CACHE = "1";
        __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
        __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
      };

      programs.steam = {
        enable = true;
        protontricks.enable = false;

        extraCompatPackages = singleton pkgs.proton-ge-bin;
        extraPackages = [
          pkgs.winetricks
          pkgs.mangohud
        ];

        config = {
          enable = true;

          onSteamRunning = "wait";
          defaultCompatTool = "proton_experimental";
          displayRatesAsBits = true;

          apps."Overwatch" = {
            id = 2357570;
            updateBehavior = "always";
            desktopEntry.enable = true;

            wrappers = [
              "gamemoderun"
              "mangohud"
            ];

            env = {
              TZ = "Europe/Warsaw";
              DXVK_CONFIG = "dxvk.trackPipelineLifetime = True";
              DXVK_HUD = "compiler";

              PROTON_ENABLE_WAYLAND = "1";
              PROTON_LOCAL_SHADER_CACHE = "1";

              __GL_SHADER_DISK_CACHE = "1";
              __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
              __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
              __GL_SHADER_DISK_CACHE_PATH = "${home}/.local/share/steam-shader-cache/overwatch";
            };
          };
        };
      };

      programs.gamemode.enable = true;

      hardware.graphics = {
        enable = true;
        enable32Bit = true; # Required for Steam and 32-bit games
      };

      security.rtkit.enable = true; # For low-latency audio

      hjemModule.xdg.data.files."Steam/steam_dev.cfg".text =
        let
          threads = toString <| floor <| config.systemInfo.threads * 0.5;
        in
        #cfg
        ''
          unShaderBackgroundProcessingThreads ${threads}
          @ShaderBackgroundProcessingThreads ${threads}
        '';
    };
}
