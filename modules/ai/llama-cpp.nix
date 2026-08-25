{ lib, ... }:
let
  inherit (lib.trivial) warnIf;

  isGpu = config: config.systemInfo.gpu.exists;
  isNvidiaGpu = config: config.systemInfo.gpu.vendor == "nVidia Corporation";

  noGpuWarning =
    program: config: value:
    warnIf (
      !isGpu config
    ) "${program}: no GPU detected or configured - CPU-only inference will be slow" value;
in
{
  flake.modules.nixos.llama-cpp =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) unique singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.attrsets) optionalAttrs mapAttrsToList;
      inherit (lib.strings) concatMapStringsSep;

      cpuMoeOffload = {
        n-gpu-layers = 99;
        cpu-moe = "on";
        n-cpu-moe = 99;
        threads = "10";
        threads-batch = "20";
      };

      ngram = {
        spec-type = "ngram-mod";
        spec-ngram-mod-n-match = "24";
        spec-ngram-mod-n-min = "48";
        spec-ngram-mod-n-max = "64";
      };

      mkUnslothQwen =
        {
          hf-repo,
          ctx-size,
          moeOffload ? true,
          ...
        }:
        {
          inherit hf-repo ctx-size;
          jinja = "on";
          chat-template-kwargs = ''{"preserve_thinking": true}'';
          no-mmproj-offload = "on";

          cache-type-k = "q8_0";
          cache-type-v = "q8_0";
        }
        # WARN: Ngram can break tool calls, apparently.
        // ngram
        // optionalAttrs moeOffload cpuMoeOffload;

      models = {
        # tps | ctx max
        # 8.4 | 262144
        "unsloth/Qwen3.6-35B-A3B:UD-IQ3_XXS" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ3_XXS";
          ctx-size = "131072";
        };

        # tps | ctx max
        # 8.3 | 262144
        "unsloth/Qwen3.6-35B-A3B:UD-IQ3_S" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ3_S";
          ctx-size = "131072";
        };

        # tps  | ctx max
        # 11.3 | 262144
        "unsloth/Qwen3.6-35B-A3B:UD-IQ4_XS" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS";
          ctx-size = "131072";
        };

        # tps | ctx max
        # 0   | 262144
        "unsloth/Qwen3.6-35B-A3B:UD-IQ4_NL_XL" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_NL_XL";
          ctx-size = "131072"; # 262144 max - untested
        };

        # tps  | ctx max
        # 25.0 | 262144
        "unsloth/Qwen3.6-35B-A3B:Q4_K_S" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_S";
          ctx-size = "262144"; # 262144 max - untested
        };

        # tps  | ctx max
        # 23.3 | 262144
        "unsloth/Qwen3.6-35B-A3B:Q4_K_XL" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_XL";
          ctx-size = "262144"; # 262144 max - untested
        };

        # tps  | ctx max
        # 21.0 | 262144
        "unsloth/Qwen3.6-35B-A3B:Q5_K_S" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:Q5_K_S";
          ctx-size = "262144"; # 262144 max - untested
        };

        # tps  | ctx max
        # 14.7 | 262144
        "unsloth/Qwen3.6-35B-A3B:Q6_K" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:Q6_K";
          ctx-size = "262144"; # 262144 max - untested
        };

        # tps  | ctx max
        # 16.4 | 262144
        "unsloth/Qwen3.6-35B-A3B:Q8_K_XL" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:Q8_K_XL";
          ctx-size = "262144"; # 262144 max - untested
        };

        # tps  | ctx max
        # 3.7  | 262144
        "unsloth/Qwen3.8-27B:UD-IQ3_XXS" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.8-27B-GGUF:UD-IQ3_XXS";
          ctx-size = "131077";
          moeOffload = false;
        };

        # tps  | ctx max
        # ??   | 1000000
        "ornith-ai/Ornith-1.5-35B-A3B-GGUF:Q4_K_M" = {
          hf-repo = "ornith-ai/Ornith-1.5-35B-A3B-GGUF:Q4_K_M";

          ctx-size = "156000";
          jinja = "on";
          cache-type-k = "q8_0";
          cache-type-v = "q8_0";
          reasoning = "on";
          batch-size = 2048;
          ubatch-size = 1024;
          temp = 0.6;
          top-p = 0.95;
          top-k = 20;
          min-p = 0.0;
          presence-penalty = 0.0;
          repeat-penalty = 1.0;
        }
        // cpuMoeOffload;

        # tps  | ctx max
        # 40   | 1000000
        "quimmedes/Ornith-1.5-35B-A3B-XYZ:Q3-XYZ" = {
          hf-repo = "quimmedes/Ornith-1.5-35B-A3B-XYZ:Q3-XYZ";

          ctx-size = "156000";
          jinja = "on";
          cache-type-k = "q8_0";
          cache-type-v = "q8_0";
          reasoning = "on";
          batch-size = 2048;
          ubatch-size = 1024;
          temp = 0.6;
          top-p = 0.95;
          top-k = 20;
          min-p = 0.0;
          presence-penalty = 0.0;
          repeat-penalty = 1.0;
        }
        // cpuMoeOffload;
      };

      # Write models preset to a file and reference it by path.
      # (The module's `settings.models-preset` expects a file path, not inline INI.)
      modelsIni = pkgs.writeText "llama-models.ini" (
        lib.generators.toINI { } (
          {
            "*" = { };
          }
          // models
        )
      );
    in
    {
      unfree.allowedNames = mkIf (isNvidiaGpu config) [
        "cuda_cccl"
        "cuda_cudart"
        "cuda_nvcc"
        "libcublas"
        "cuda_nvrtc"
      ];

      services.llama-cpp = {
        enable = noGpuWarning "llama-cpp" config true;
        package = pkgs.llama-cpp.override { cudaSupport = if (isNvidiaGpu config) then true else false; };

        settings = {
          host = "127.0.0.1";
          port = 11435;

          parallel = 1;
          flash-attn = "on";
          load-mode = "mmap";

          # Pass path to generated INI file instead of inline content
          models-preset = modelsIni;
        };
      };

      hjemModule = {
        systemd.services.llama-cpp-install-models = {
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "1h";
          };
          script =
            concatMapStringsSep "\n" (repo: ''
              echo "Downloading ${repo}..."
              ${getExe pkgs.llama-cpp} download --hf-repo ${repo}
            '')
            <| unique
            <| mapAttrsToList (_: model: model.hf-repo) models;
        };

        systemd.services.llama-cpp-install-models-trigger = {
          after = singleton "nixos-activation.service";
          wantedBy = singleton "default.target";

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl --user start --no-block llama-cpp-install-models.service";
          };
        };
      };
    };
}
