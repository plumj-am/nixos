{
  # Not available as a service on nix-darwin need another solution.
  flake.modules.nixos.litellm =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) mkForce;
      inherit (config.age) secrets;

      # Check with:
      # curl -s https://opencode.ai/zen/go/v1/models -H (cat /run/agenix/opencodeGoKey) | jq '.data[].id'
      models = [
        # MINIMAX works
        {
          name = "minimax-m2.7";
          id = "anthropic/minimax-m2.7";
          context = 204800;
        }
        {
          name = "minimax-m2.5";
          id = "anthropic/minimax-m2.5";
          context = 204800;
        }
        # GLM does not work yet
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
        # KIMI works
        {
          name = "kimi-k2.5";
          id = "moonshot/kimi-k2.5";
          context = 262144;
        }
        {
          name = "kimi-k2.6";
          id = "moonshot/kimi-k2.6";
          context = 262144;
        }
        # MIMO does not work yet
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
        # QWEN does not work yet
        {
          name = "qwen3.6-plus";
          id = "alibaba/qwen3.6-plus";
          context = 1048576;
        }
        {
          name = "qwen3.5-plus";
          id = "alibaba/qwen3.5-plus";
          context = 262144;
        }
        # DEEPSEEK works
        {
          name = "deepseek-v4-pro";
          id = "deepseek/deepseek-v4-pro";
          context = 1048576;
        }
        {
          name = "deepseek-v4-flash";
          id = "deepseek/deepseek-v4-flash";
          context = 1048576;
        }
        # HY3 does not work yet
        {
          name = "hy3-preview";
          id = "openai/hy3-preview";
          context = 262144;
        }
      ];

      mkModel =
        {
          name,
          id,
          stream ? false,
          needsMessagesEndpoint ? false,
          ...
        }:
        {
          model_name = name;
          litellm_params = {
            model = id;
            api_base = "https://opencode.ai/zen/go/v1/${
              if needsMessagesEndpoint then "messages" else "chat/completions"
            }";
            api_key = "os.environ/OPENCODE_GO_KEY";
            # modify_params = true;
            drop_params = true;
            inherit stream;
          };
        };
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

          LITELLM_HTTPX_TIMEOUT = "120"; # Match `request_timeout` below.
          LITELLM_HTTPX_MAX_CONNECTIONS = "128";
          LITELLM_HTTPX_KEEPALIVE = "true";
          LITELLM_HTTPX_MAX_KEEPALIVE_CONNECTIONS = "64";
          LITELLM_HTTPX_RETRIES = "5";
        };

        settings = {
          model_list = map mkModel models;

          litellm_settings = {
            set_verbose = true;

            telemetry = false;

            modify_params = false;
            drop_params = true;

            enable_request_caching = true;
            request_cache_max_entries = 10000;
            max_parallel_requests = 32;
            request_timeout = 120000;
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
    };
}
