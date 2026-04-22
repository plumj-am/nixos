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

      models = [
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
        {
          name = "deepseek-v4-pro";
          id = "openai/deepseek-v4-pro";
          context = 1048576;
        }
        {
          name = "deepseek-v4-flash";
          id = "openai/deepseek-v4-flash";
          context = 1048576;
        }
      ];

      mkModel =
        {
          name,
          id,
          stream ? true,
          ...
        }:
        {
          model_name = name;
          litellm_params = {
            model = id;
            api_base = "https://opencode.ai/zen/go/v1";
            api_key = "os.environ/OPENCODE_GO_KEY";
            modify_params = true;
            drop_params = false;
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

            drop_params = true;
            telemetry = false;

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
