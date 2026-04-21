{
  flake.modules.common.ai-options =
    {
      lib,
      ...
    }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.modules) mkDefault;
      inherit (lib.lists) foldl';
      inherit (lib.attrsets) recursiveUpdate;
      inherit (lib.types)
        int
        listOf
        nullOr
        str
        submodule
        bool
        ;

      modelType = submodule (
        { config, ... }:
        {
          options = {
            name = mkOption {
              type = str;
              description = "Friendly model identifier - defaults to id";
            };
            id = mkOption {
              type = str;
              description = "Proper model identifier";
            };
            size = mkOption {
              type = nullOr str;
              default = null;
              description = "Approximate download size";
            };
            stream = mkOption {
              type = bool;
              default = true;
              description = "If the model supports streaming";
            };
            reasoning = mkOption {
              type = bool;
              default = true;
              description = "If the model supports reasoning";
            };
            developerRole = mkOption {
              type = bool;
              default = false;
              description = ''
                If the model supports the openai developer role

                System prompt injection issues? Try changing this option
              '';
            };
            context = mkOption {
              type = nullOr int;
              default = null;
              description = "Context window length, or null if unknown";
            };
          };

          config.name = mkDefault config.id;
        }
      );

      mkModelOptions = ns: {
        ai.models.${ns} = {
          all = mkOption {
            type = listOf modelType;
            default = [ ];
            description = "All known ${ns} AI models";
          };
          enabledIDs = mkOption {
            type = listOf str;
            default = [ ];
            description = ''
              Enabled ${ns} AI models by ID
              If empty, all are enabled
            '';
          };
        };
      };
    in
    {
      options =
        foldl' recursiveUpdate { }
        <| map mkModelOptions [
          "local"
          "litellm"
        ];
    };

  flake.modules.common.ai-config = {
    ai.models.local.enabledIDs = [
      "huihui_ai/qwen3.6-abliterated:35b"
      "mistral-nemo:12b"
    ];

    ai.models.litellm.enabledIDs = [ ];

    ai.models.local.all = [
      # Qwen
      {
        id = "qwen3.5:0.8b";
        size = "1.0GB";
        context = 262144;
      }
      {
        id = "qwen3.5:2b";
        size = "2.7GB";
        context = 262144;
      }
      {
        id = "qwen3.5:4b";
        size = "3.4GB";
        context = 262144;
      }
      {
        id = "qwen3.5:9b";
        size = "6.6GB";
        context = 262144;
      }
      {
        id = "qwen3.5:27b";
        size = "17GB";
        context = 262144;
      }
      {
        id = "qwen3.6:35b";
        size = "24GB";
        context = 262144;
      }
      {
        name = "qwen3.6-abliterated:35b";
        id = "huihui_ai/qwen3.6-abliterated:35b";
        size = "24GB";
        context = 262144;
      }

      # GPT OSS
      {
        id = "gpt-oss:20b";
        size = "14GB";
        context = 128000;
      }

      # GLM
      {
        name = "glm-4.7-flash-q4:30b";
        id = "glm-4.7-flash:q4_K_M";
        size = "19GB";
        context = null;
      }
      {
        name = "glm-4.7-flash-abliterated-q4:30b";
        id = "huihui_ai/glm-4.7-flash-abliterated:q4_K_S";
        size = "17GB";
        context = null;
      }
      {
        name = "glm-4.7-flash-abliterated-q4:30b";
        id = "huihui_ai/glm-4.7-flash-abliterated:q4_K";
        size = "19GB";
        context = null;
      }

      # Gemma
      {
        id = "gemma4:e2b";
        size = "7.2GB";
        context = 128000;
      }
      {
        id = "gemma4:e4b";
        size = "9.6GB";
        context = 128000;
      }
      {
        id = "gemma4:26b";
        size = "18GB";
        context = 256000;
      }
      {
        id = "gemma4:31b";
        size = "20GB";
        context = 256000;
      }

      # Mistral
      {
        id = "mistral:7b";
        size = "4.4GB";
        context = 32000;
      }
      {
        id = "mistral-nemo:12b";
        size = "7.1GB";
        context = 1000000;
      }
      {
        id = "mistral-small:22b";
        size = "13GB";
        context = 128000;
      }
      {
        id = "mistral-small:24b";
        size = "14GB";
        context = 32000;
      }
      {
        id = "mistral-small3.2:24b";
        size = "15GB";
        context = 128000;
      }
      {
        name = "mistral-small-abliterated:24b";
        id = "huihui_ai/mistral-small-abliterated:24b";
        size = "14GB";
        context = 32000;
      }

      # Nvidia
      {
        id = "nemotron-3-nano:4b";
        size = "2.8GB";
        context = 256000;
      }
      {
        id = "nemotron-3-nano:30b";
        size = "24GB";
        context = 1000000;
      }
      {
        id = "nemotron-mini:4b";
        size = "2.7GB";
        context = 4000;
      }
      {
        id = "nemotron-cascade-2:30b";
        size = "24GB";
        context = 256000;
      }

      # Granite
      {
        id = "granite4:350m";
        size = "0.7GB";
        context = 32000;
      }
      {
        id = "granite4:1b";
        size = "3.3GB";
        context = 128000;
      }
      {
        id = "granite4:3b";
        size = "2.1GB";
        context = 128000;
      }
      {
        id = "granite3.3:2b";
        size = "1.5GB";
        context = 128000;
      }
      {
        id = "granite3.3:8b";
        size = "4.9GB";
        context = 128000;
      }
      {
        id = "granite3.1-moe:1b";
        size = "1.4GB";
        context = 128000;
      }
      {
        id = "granite3.1-moe:3b";
        size = "2.0GB";
        context = 128000;
      }
      {
        id = "granite-code:3b";
        size = "2.0GB";
        context = 125000;
      }
      {
        id = "granite-code:8b";
        size = "4.6GB";
        context = 125000;
      }
      {
        id = "granite-code:20b";
        size = "12GB";
        context = 8000;
      }
    ];

    ai.models.litellm.all = [
      {
        name = "minimax-m2.7";
        id = "openai/minimax-m2.7";
        context = 204800;
      }
      {
        name = "minimax-m2.5";
        id = "openai/minimax-m2.5";
        context = 204800;
      }

      {
        name = "glm-5.1";
        id = "zai/glm-5.1";
        context = 204800;
      }
      {
        name = "glm-5";
        id = "zai/glm-5";
        context = 204800;
      }
      {
        name = "kimi-k2.5";
        id = "moonshot/kimi-k2.5";
        stream = false;
        context = 262144;
      }
      {
        name = "kimi-k2.6";
        id = "moonshot/kimi-k2.6";
        stream = false;
        context = 262144;
      }
      {
        name = "mimo-v2-pro";
        id = "openai/mimo-v2-pro";
        context = 1048576;
      }
      {
        name = "mimo-v2-omni";
        id = "openai/mimo-v2-omni";
        context = 262144;
      }
      {
        name = "mimo-v2.5-pro";
        id = "openai/mimo-v2.5-pro";
        context = 1048576;
      }
      {
        name = "mimo-v2.5";
        id = "openai/mimo-v2.5";
        context = 262144;
      }
      {
        name = "qwen3.6-plus";
        id = "openai/qwen3.6-plus";
        context = 1048576;
      }
      {
        name = "qwen3.5-plus";
        id = "openai/qwen3.5-plus";
        context = 262144;
      }
    ];
  };
}
