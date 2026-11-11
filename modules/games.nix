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
      inherit (config.systemInfo) gpu;
      inherit (config.users.users.jam) home;

      isGpu = gpu.exists;

      threads = toString <| floor <| config.systemInfo.threads * 0.5;

      grovePkgs = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [
        inputs.steam-config.nixosModules.default
        inputs.grove.nixosModules.gamemode
      ];

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

      environment.systemPackages = [
        grovePkgs.gmrs-client
        grovePkgs.gmrs-client-auto

        (pkgs.bottles.override { removeWarningPopup = true; })
      ];

      boot.kernelPackages = pkgs.linuxPackages_zen;

      programs.steam = {
        enable = true;
        protontricks.enable = true;

        extraCompatPackages = singleton pkgs.proton-ge-bin;
        extraPackages = [
          pkgs.mangohud
          pkgs.winetricks
          pkgs.pulseaudio # Needs `pactl` at runtime.
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

              DXVK_CONFIG = "dxvk.trackPipelineLifetime = True;dxvk.enableGraphicsPipelineLibrary = True;dxvk.numCompilerThreads = ${threads}";
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

      services.gamemode = {
        enable = true;
        package = grovePkgs.gmrs-daemon;
        helperPackage = grovePkgs.gmrs-priv;
      };

      users.users.jam.extraGroups = singleton "gamemode";

      security.pam.loginLimits = singleton {
        domain = "@gamemode";
        type = "-";
        item = "nice";
        value = "-10";
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true; # Required for Steam and 32-bit games
      };

      security.rtkit.enable = true; # For low-latency audio

      hjemModule = {
        xdg.config.files."MangoHud/MangoHud.conf".text = ''
          font_size=18
          background_alpha=0.2
          fps_metrics=avg,0.01

          gpu_temp
          gpu_core_clock
          vram

          cpu_stats
          cpu_temp
          cpu_mhz
          procmem
        '';

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
