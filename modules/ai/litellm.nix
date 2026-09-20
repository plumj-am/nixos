{ self, ... }:
{

  flake.modules.common.ai-agents = self.modules.common.litellm;
  flake.modules.common.litellm =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) attrNames;
      inherit (lib.lists) concatMap;
      inherit (config) sops;

      # Per-1M USD from https://commandcode.ai/models, divided by 1e6.
      models = {
        "meta/muse-spark-1.3-contributor" = {
          input_cost_per_token = 1.0e-7; # $0.10/M
          output_cost_per_token = 2.0e-7; # $0.20/M
          cache_creation_input_token_cost = 0;
          cache_read_input_token_cost = 2.0e-9; # $0.002/M
        };
        # peak times: 01-04 & 06-10 UTC Mon-Fri.
        "deepseek/deepseek-v4.1-flash" = {
          input_cost_per_token = 1.5e-7; # $0.15/M off-peak ($0.3/M peak)
          output_cost_per_token = 6.0e-7; # $0.60/M off-peak ($1.20/M peak)
          cache_creation_input_token_cost = 0;
          cache_read_input_token_cost = 3.0e-9; # $0.003/M off-peak ($0.006/M peak)
        };
        "poolside/laguna-s-2.1-free" = {
          input_cost_per_token = 0;
          output_cost_per_token = 0;
          cache_creation_input_token_cost = 0;
          cache_read_input_token_cost = 0;
        };
        "Qwen/Qwen3.8-Flash" = {
          input_cost_per_token = 1.6e-7; # $0.16/M
          output_cost_per_token = 4.7e-7; # $0.47/M
          cache_creation_input_token_cost = 0;
          cache_read_input_token_cost = 2.0e-8; # $0.02/M
        };
      };

      deployment = model_name: model: model_info: n: {
        inherit model_name model_info;
        litellm_params = {
          model = "openai/${model}";
          api_base = "https://api.commandcode.ai/provider/v1";
          api_key = "os.environ/COMMANDCODE_${toString n}_API_KEY";
        };
      };
    in
    {
      sops.templates."litellm-env" = {
        content = ''
          COMMANDCODE_1_API_KEY=${sops.placeholder."commandcode-1-key"}
          COMMANDCODE_2_API_KEY=${sops.placeholder."commandcode-2-key"}
        '';
      };

      services.litellm = {
        enable = true;

        host = "127.0.0.1";
        port = 8023;

        environmentFile = sops.templates."litellm-env".path;

        settings.model_list =
          concatMap (model: [
            # shared pool
            (deployment model model models.${model} 1)
            (deployment model model models.${model} 2)
            # pinned groups, used only as fallbacks
            (deployment "${model}-key1" model models.${model} 1)
            (deployment "${model}-key2" model models.${model} 2)
          ])
          <| attrNames models;

        settings.litellm_settings = {
          drop_params = true;
        };

        settings.router_settings = {
          routing_strategy = "simple-shuffle";
          num_retries = 3;
          allowed_fails = 1;
          retry_after = 0;
          cooldown_time = 5;
          enable_pre_call_checks = true;
          model_group_alias = {
            "qwen/qwen3.8-flash" = "Qwen/Qwen3.8-Flash";
          };
          fallbacks =
            map (model: {
              ${model} = [
                "${model}-key1"
                "${model}-key2"
              ];
            })
            <| attrNames models;
        };
      };
    };
}
