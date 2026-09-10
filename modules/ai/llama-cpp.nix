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
      inherit (lib.modules) mkIf;

      mkUnslothQwen =
        rest:
        {
          no-mmproj-auto = true;
          n-gpu-layers = 999;

          batch-size = 2048;
          ubatch-size = 1024;

          cache-type-k = "q8_0";
          cache-type-v = "q8_0";

          jinja = true;
          reasoning-format = "auto";

          temp = 1.0;
          top-p = 0.95;
          top-k = 20;
          min-p = 0.0;
        }
        // rest;

      models = {
        "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_XL" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_XL";
          ctx-size = 32768;
          override-tensor = "blk\\.(3[2-9])\\.ffn_(gate|up|down)_exps\\.weight=CPU";
        };

        "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS";
          ctx-size = 32768;
          override-tensor = "blk\\.(3[0-9])\\.ffn_(gate|up|down)_exps\\.weight=CPU";
        };

        "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_NL" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-IQ4_NL";
          ctx-size = 32768;
          override-tensor = "blk\\.(3[0-9])\\.ffn_(gate|up|down)_exps\\.weight=CPU";
        };

        "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q3_K_XL" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q3_K_XL";
          ctx-size = 32768;
          override-tensor = "blk\\.(29|3[0-9])\\.ffn_(gate|up|down)_exps\\.weight=CPU";
        };

        "unsloth/Qwen3.5-9B-GGUF:UD-Q4_K_XL" = mkUnslothQwen {
          hf-repo = "unsloth/Qwen3.5-9B-GGUF:UD-Q4_K_XL";
          ctx-size = 32768;
        };
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
    };
}
