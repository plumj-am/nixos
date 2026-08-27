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
      inherit (lib.trivial) floor warnIf;

      inherit (config.users.users.jam) home;
      inherit (config.systemInfo) gpu;

      isGpu = gpu.exists;

      threads = toString <| floor <| config.systemInfo.threads * 0.5;
    in
    {
      imports = singleton inputs.steam-config.nixosModules.default;

      unfree.allowedNames = [
        "steam"
        "steam-unwrapped"
      ];

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
        protontricks.enable = true;

        extraCompatPackages = singleton pkgs.proton-ge-bin;
        extraPackages = [
          pkgs.mangohud
          pkgs.winetricks
        ];

        config = {
          enable = warnIf (
            !isGpu
          ) "steam: no GPU detected or configured - GPU-accelerated gaming will be impossible" true;

          onSteamRunning = "wait";
          defaultCompatTool = "proton_experimental";
          displayRatesAsBits = true;

          apps."2357570" = {
            name = "Overwatch";
            updateBehavior = "always";
            desktopEntry.enable = true;

            wrappers = [
              "mangohud"
              "gamemoderun"
            ];

            env = {
              TZ = "Europe/Warsaw";

              DXVK_CONFIG = "dxvk.trackPipelineLifetime=True;dxvk.enableGraphicsPipelineLibrary=True;dxvk.numCompilerThreads=${threads}";
              DXVK_HUD = "compiler";

              PROTON_ENABLE_WAYLAND = "1";
              PROTON_LOCAL_SHADER_CACHE = "1";

              __GL_SHADER_DISK_CACHE = "1";
              __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
              __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
              __GL_SHADER_DISK_CACHE_PATH = "${home}/.local/share/steam-shader-cache/overwatch";

              LD_PRELOAD = "";
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

      hjemModule = {
        xdg.data.files."steam-shader-cache/overwatch".type = "directory";

        xdg.data.files."Steam/steam_dev.cfg".text =
          #cfg
          ''
            unShaderBackgroundProcessingThreads ${threads}
            @ShaderBackgroundProcessingThreads ${threads}
          '';
      };
    };
}
