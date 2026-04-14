{
  # Not available as a service on nix-darwin need another solution.
  flake.modules.nixos.litellm =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) mkForce;
      inherit (lib.lists) map;
      inherit (config.age) secrets;

      mkModel =
        {
          modelName,
          modelFull,
          stream ? true,
          needsV1 ? true,
        }:
        {
          model_name = modelName;
          litellm_params = {
            model = modelFull;
            api_base = if needsV1 then "https://opencode.ai/zen/go/v1" else "https://opencode.ai/zen/go";
            api_key = "os.environ/OPENCODE_GO_KEY";
            drop_params = true;
            inherit stream;
          };
        };

      models = [
        {
          modelName = "minimax-m2.7";
          modelFull = "minimax/minimax-m2.7";
          needsV1 = false;
        }
        {
          modelName = "minimax-m2.5";
          modelFull = "minimax/minimax-m2.5";
          needsV1 = false;
        }

        {
          modelName = "glm-5.1";
          modelFull = "zai/glm-5.1";
        }
        {
          modelName = "glm-5";
          modelFull = "zai/glm-5";
        }
        {
          modelName = "kimi-k2.5";
          modelFull = "moonshot/kimi-k2.5";
          stream = false;
        }
        {
          modelName = "mimo-v2-pro";
          modelFull = "openai/mimo-v2-pro";
        }
        {
          modelName = "mimo-v2-omni";
          modelFull = "openai/mimo-v2-omni";
        }
        {
          modelName = "qwen3.6-plus";
          modelFull = "openai/qwen3.6-plus";
        }
        {
          modelName = "qwen3.5-plus";
          modelFull = "openai/qwen3.5-plus";
        }
      ];
    in
    {
      age.secrets.opencodeGoEnvironment = {
        rekeyFile = ../../secrets/opencode-go-environment.age;
        owner = "litellm";
        group = "litellm";
        mode = "600";
      };

      unfree.allowedNames = [
        "cuda_cudart"
        "cuda_nvcc"
        "cuda_cccl"
        "libcublas"
      ];

      users.users.litellm = {
        group = "litellm";
        isSystemUser = true;
      };
      users.groups.litellm = { };

      systemd.services.litellm.serviceConfig.DynamicUser = mkForce false;

      services.litellm = {
        enable = true;
        port = 4000;

        environmentFile = secrets.opencodeGoEnvironment.path;

        environment = {
          SCARF_NO_ANALYTICS = "True";
          DO_NOT_TRACK = "True";
          ANONYMIZED_TELEMETRY = "False";

          LITELLM_LOCAL_CACHE = "true";

          LITELLM_HTTPX_TIMEOUT = "20";
          LITELLM_HTTPX_MAX_CONNECTIONS = "128";
          LITELLM_HTTPX_KEEPALIVE = "true";
          LITELLM_HTTPX_MAX_KEEPALIVE_CONNECTIONS = "64";
          LITELLM_HTTPX_RETRIES = "5";
        };

        settings = {
          model_list = map mkModel models ++ [
            {
              model_name = "ollama-embedding-model";
              litellm_params = {
                model = "ollama/all-minilm";
                api_base = "http://localhost:11434";
                drop_params = true;
                stream = false;
              };
            }
          ];

          litellm_settings = {
            drop_params = true;
            telemetry = false;

            enable_request_caching = true;
            request_cache_max_entries = 10000;
            max_parallel_requests = 32;
            request_timeout = 120000;

            cache = true;
            cache_params = {
              # type = "redis-semantic"; # Can't use it yet. Error: `ModuleNotFoundError: No module named 'redisvl'`
              # See here: <https://github.com/NixOS/nixpkgs/blob/3da2922a907d285ff3d82bc7654f0ae483ad1b0f/pkgs/development/python-modules/litellm/default.nix#L115>
              type = "redis";
              host = "127.0.0.1";
              port = 6379;

              ttl = 3600;
              mode = "default_on";

              namespace = "litellm";

              redis_semantic_cache_embedding_model = "ollama-embedding-model";

              supported_call_types = [
                "acompletion"
                "atext_completion"
                "aembedding"
              ];

              similarity_threshold = 0.82; # For MiniLM.

              max_connections = 128;
            };
          };

          router_settings = {
            enable_pre_call_checks = true;

            retry_policy = {
              TimeoutErrorRetries = 3;
              RateLimitErrorRetries = 3;
              InternalServerErrorRetries = 3;
            };

            allowed_fails = 3;
            cooldown_time = 30;
          };

          general_settings = {
            disable_spend_logs = true;
            disable_master_key_return = true;
            store_model_in_db = false;

            global_max_parallel_requests = 32;
          };
        };
      };

      services.redis.servers."litellm" = {
        enable = true;
        port = 6379;
        settings.maxmemory-policy = "allkeys-lru";
      };

      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        loadModels = [ "all-minilm" ];

        environmentVariables = {
          OLLAMA_NUM_PARALLEL = "4";
          OLLAMA_MAX_LOADED_MODELS = "2";
        };
      };

      systemd.services.ollama.serviceConfig = {
        Restart = "always";
      };
      systemd.services.litellm.serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
        StartLimitIntervalSec = "2min";
        StartLimitBurst = 5;
        TimeoutStartSec = "120s";
      };

      systemd.services.litellm.after = [
        "redis-litellm.service"
        "ollama.service"
      ];
      systemd.services.litellm.wants = [
        "redis-litellm.service"
        "ollama.service"
      ];
    };
}
