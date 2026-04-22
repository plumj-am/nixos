{
  flake.modules.nixos.llama-cpp =
    { pkgs, ... }:
    let

      cpuMoeOffload = {
        n-gpu-layers = -1;
        cpu-moe = "on";
      };

      # ngram = {
      #   spec-type = "ngram-mod";
      #   spec-ngram-size-n = "24";
      #   draft-min = "12";
      #   draft-max = "48";
      # };

      mkUnslothQwen =
        name: rest:
        {
          hf-repo = "unsloth/${name}";
          jinja = "on";
          chat-template-kwargs = ''{"preserve_thinking": true}'';
          no-mmproj-offload = "on";
        }
        # Ngram can break tool calls, apparently.
        // rest
        // cpuMoeOffload;
    in
    {
      services.llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp.override { cudaSupport = true; };

        port = 11435;

        extraFlags = [
          "--parallel"
          "1"
          "--flash-attn"
          "on"
          "--mmap"
        ];

        modelsPreset = {
          # q4  | q4 ngram | q8  | ctx max | load
          # 8.4 | 11.5     | 8.1 | 262144  | ~40 sec
          "unsloth/Qwen3.6-35B-A3B:UD-IQ3_XXS" = mkUnslothQwen "Qwen3.6-35B-A3B-GGUF:UD-IQ3_XXS" {
            # cache-type-k = "q4_0";
            # cache-type-v = "q4_0";
            # ctx-size = "262144";
            # or
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            ctx-size = "131072";
          };

          # q4 tps | ctx max | load
          # ~8.3   | 262144  | ~4 min
          "unsloth/Qwen3.6-35B-A3B:UD-IQ3_S" = mkUnslothQwen "Qwen3.6-35B-A3B:UD-IQ3_S" {
            cache-type-k = "q4_0";
            cache-type-v = "q4_0";
            ctx-size = "131072";
          };

          # q4 tps | ctx max | load
          # ~8.0   | 262144  | ~9 min
          "unsloth/Qwen3.6-35B-A3B:UD-IQ4_XS" = mkUnslothQwen "Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS" {
            cache-type-k = "q4_0";
            cache-type-v = "q4_0";
            ctx-size = "131072";
          };

          # q4 tps | ctx max | load
          # ~8.9   | 262144  | ~0
          "unsloth/Qwen3.6-35B-A3B:UD-IQ4_NL_XL" = mkUnslothQwen "Qwen3.6-35B-A3B-GGUF:UD-IQ4_NL_XL" {
            cache-type-k = "q4_0";
            cache-type-v = "q4_0";
            ctx-size = "131072"; # 262144 max - untested
          };

          # q4 tps | ctx max | load
          # ~0     | 262144  | ~0
          "unsloth/Qwen3.6-27B:UD-IQ3_XXS" = mkUnslothQwen "Qwen3.6-27B-GGUF:UD-IQ3_XXS" {
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            ctx-size = "131072"; # 262144 max - untested
          };

          # q4 tps | ctx max | load
          # ~0     | 262144  | ~0
          "unsloth/Qwen3.6-27B:IQ4_XS" = mkUnslothQwen "Qwen3.6-27B-GGUF:IQ4_XS" {
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            ctx-size = "131072"; # 262144 max - untested
          };

          # q4 tps | ctx max | load
          # ~0     | 262144  | ~0
          "unsloth/Qwen3.6-27B:UD-Q4_K_XL" = mkUnslothQwen "Qwen3.6-27B-GGUF:UD-Q4_K_XL" {
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            ctx-size = "131072"; # 262144 max - untested
          };

          # q4 tps | ctx max | load
          # ~0     | 262144  | ~0
          "unsloth/Qwen3.6-27B:UD-Q4_XS" = mkUnslothQwen "Qwen3.6-27B-GGUF:UD-IQ4_XS" {
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            ctx-size = "131072"; # 262144 max - untested
          };

          # q4 tps | ctx max | load
          # ~1.3   | 4096    | ~0
          "Jackrong/Qwopus3.6-27B-v1-preview:Q3_K_L" = cpuMoeOffload // {
            hf-repo = "Jackrong/Qwopus3.6-27B-v1-preview-GGUF:Q3_K_L";
            cache-type-k = "q4_0";
            cache-type-v = "q4_0";
            ctx-size = "4096"; # preview model
          };

          # q4 tps | ctx max/highest | load
          # ~0     | 262144          | ~0
          "Jackrong/qwen3.5-27B-GLM5.1-Dist:IQ4_XS" = cpuMoeOffload // {
            hf-repo = "Jackrong/Qwen3.5-27B-GLM5.1-Distill-v1-GGUF:IQ4_XS";
            cache-type-k = "q4_0";
            cache-type-v = "q4_0";
            ctx-size = "131072";
          };

          # q4 tps | ctx max/highest | load
          # 1.6    | 262144 / 65531  | ~0
          "Jackrong/Qwen3.5-27B-Opus-4.6-Reasoning-Dist:Q4_K_M" = cpuMoeOffload // {
            hf-repo = "Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-GGUF:Q4_K_M";
            cache-type-k = "q4_0";
            cache-type-v = "q4_0";
            ctx-size = "65531";
          };

          # q4 tps | ctx max | load
          # ~0     | 262144  | ~0
          "Jackrong/Qwopus3.5-27B-v3.5-GGUF" = cpuMoeOffload // {
            hf-repo = "Jackrong/Qwopus3.5-27B-v3.5-GGUF:IQ4_XS";
            cache-type-k = "q4_0";
            cache-type-v = "q4_0";
            ctx-size = "131072";
          };

          # q4 tps | ctx max | load
          # ~0     | 262144  | ~0
          "unsloth/gemma-4-31B-it-GGUF-UD-IQ3_XXS" = cpuMoeOffload // {
            hf-repo = "unsloth/gemma-4-31B-it-GGUF:IQ3_XXS";
            cache-type-k = "q4_0";
            cache-type-v = "q4_0";
            ctx-size = "131072"; # 262144 max - untested
          };
        };
      };
    };
}
