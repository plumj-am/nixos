{
  flake.modules.nixos.llama-cpp =
    { pkgs, ... }:
    let

      cpuMoeOffload = {
        n-gpu-layers = 99;
        cpu-moe = "on";
        n-cpu-moe = 99;
        threads = "10";
        threads-batch = "20";
      };

      ngram = {
        spec-type = "ngram-mod";
        spec-ngram-size-n = "24";
        draft-min = "12";
        draft-max = "48";
      };

      mkUnslothQwen =
        { name, ctx, ... }:
        {
          hf-repo = "unsloth/${name}";
          jinja = "on";
          chat-template-kwargs = ''{"preserve_thinking": true}'';
          no-mmproj-offload = "on";
          ctx-size = ctx;

          cache-type-k = "q8_0";
          cache-type-v = "q8_0";
        }
        # WARN: Ngram can break tool calls, apparently.
        // ngram
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
          # tps | ctx max | ctx max local
          # 8.4 | 262144  |
          "unsloth/Qwen3.6-35B-A3B:UD-IQ3_XXS" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:UD-IQ3_XXS";
            ctx = "131072";
          };

          # tps | ctx max | ctx max local
          # 8.3 | 262144  |
          "unsloth/Qwen3.6-35B-A3B:UD-IQ3_S" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:UD-IQ3_S";
            ctx = "131072";
          };

          # tps  | ctx max | ctx max local
          # 11.3 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:UD-IQ4_XS" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS";
            ctx = "131072";
          };

          # tps | ctx max | ctx local max
          # 0   | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:UD-IQ4_NL_XL" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:UD-IQ4_NL_XL";
            ctx = "131072"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 25.0 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q4_K_S" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q4_K_S";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 23.3 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q4_K_XL" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q4_K_XL";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 21.0 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q5_K_S" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q5_K_S";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 14.7 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q6_K" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q6_K";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 16.4 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q8_K_XL" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q8_K_XL";
            ctx = "262144"; # 262144 max - untested
          };

          # tps | ctx max | ctx max local
          # 0   | 262144  | 0
          "unsloth/gemma-4-31B-it-GGUF-UD-IQ3_XXS" = cpuMoeOffload // {
            hf-repo = "unsloth/gemma-4-31B-it-GGUF:IQ3_XXS";
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            ctx-size = "131072"; # 262144 max - untested
          };
        };
      };
    };
}
