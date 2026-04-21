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
      inherit (lib.lists) map filter elem;
      inherit (config.age) secrets;

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

      litellmModels = config.ai.models.litellm;

      enabledModels =
        if litellmModels.enabledIDs == [ ] then
          litellmModels.all
        else
          filter (m: elem m.id litellmModels.enabledIDs) litellmModels.all;
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
          model_list = map mkModel enabledModels;

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
