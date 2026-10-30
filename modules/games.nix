{ self, ... }:
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
    in
    {
      imports = [
        self.modules.nixos.game-nix-yield

        inputs.steam-config.nixosModules.default
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

      environment.systemPackages = singleton <| pkgs.bottles.override { removeWarningPopup = true; };

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

      programs.gamemode.enable = true;

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

  flake.modules.nixos.game-nix-yield =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe';
      inherit (lib.strings) concatStringsSep;

      # Steam's reaper process lives for the whole game session, so its presence
      # is a game-agnostic "game running" signal.
      gamePattern = "ubuntu12_32/reaper SteamLaunch";

      gameProperties = [
        "CPUWeight=20"
        "IOWeight=20"
        "MemoryHigh=50%"
        # No MemorySwapMax: builds may use swap freely while a game runs. The
        # oomd swap trip point is not affected either way - SwapUsedLimit= is
        # measured against system-wide swap, not a per-cgroup `memory.swap.max`
        # (see oomd.conf(5)). `memory.high` throttles; the swap kill stays a
        # system-level backstop.
        #
        # `memory.high` throttling raises the slice's own PSI, which the oomd
        # policy would otherwise answer with a kill. While a game runs, builds
        # are throttled instead of killed: pressure kills are off, and the
        # kernel OOM killer inside the slice remains the backstop.
        "ManagedOOMMemoryPressure=auto"
      ];

      idleProperties = [
        "CPUWeight=100"
        "IOWeight=100"
        "MemoryHigh=infinity"
        # Restore the "sacrifice builds" policy from modules/systemd-oomd.nix.
        "ManagedOOMMemoryPressure=kill"
      ];

      apply =
        properties:
        "${getExe' pkgs.systemd "systemctl"} set-property --runtime nix.slice "
        + concatStringsSep " " properties;
    in
    {
      systemd.services.game-nix-yield = {
        description = "Throttle Nix builds while a Steam game runs";

        serviceConfig = {
          Type = "oneshot";
          RuntimeDirectory = "game-nix-yield";
          RuntimeDirectoryPreserve = "yes";
          ExecStart =
            pkgs.writers.writeNu "game-nix-yield.nu"
              # nu
              ''
                let state = "/run/game-nix-yield/state"

                let want = if (^${getExe' pkgs.procps "pgrep"} --full '${gamePattern}' | complete).exit_code == 0 {
                  "game"
                } else {
                  "idle"
                }

                let have = if ($state | path exists) { open --raw $state | str trim } else { "idle" }

                if $want == $have { exit 0 }

                match $want {
                  "game" => { ${apply gameProperties} },
                  _      => { ${apply idleProperties} }
                }

                $want | save --force $state
              '';
        };
      };

      systemd.timers.game-nix-yield = {
        wantedBy = singleton "timers.target";

        timerConfig = {
          OnBootSec = "30s";
          OnUnitActiveSec = "3s";
          AccuracySec = "1s";
        };
      };
    };
}
