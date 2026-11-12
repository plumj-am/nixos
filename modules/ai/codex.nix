{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.codex;
  flake.modules.common.codex =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets)
        listToAttrs
        mapAttrs'
        nameValuePair
        ;
      inherit (lib.lists)
        elem
        filter
        findFirst
        head
        imap0
        singleton
        ;
      inherit (lib.strings) fromJSON readFile;
      inherit (config.ai) defaultModels;

      provider = config.ai.providers.headroomVineProxy;
      providerKey = provider.name;
      modelInfo =
        id:
        findFirst (
          model: model.id == id
        ) (throw "codex: model ${id} is not in config.ai.models") config.ai.models;

      effortLevels = [
        "minimal"
        "low"
        "medium"
        "high"
        "xhigh"
        "max"
      ];
      effortRanks = listToAttrs <| imap0 (rank: effort: nameValuePair effort rank) effortLevels;

      reasoningLevels =
        model:
        if model ? thinking && model.thinking != null then
          let
            minRank = effortRanks.${model.thinking.minLevel};
            maxRank = effortRanks.${model.thinking.maxLevel};
          in
          filter (effort: effortRanks.${effort} >= minRank && effortRanks.${effort} <= maxRank) effortLevels
        else
          [ ];

      defaultReasoningLevel =
        levels:
        if levels == [ ] then
          null
        else if elem "high" levels then
          "high"
        else
          head levels;

      mkProfile =
        model:
        let
          levels = reasoningLevels <| modelInfo model;
        in
        {
          inherit model;
          model_provider = provider.name;
          model_reasoning_effort = defaultReasoningLevel levels;
        };

      smallProfile = mkProfile defaultModels.small;
      bigProfile = mkProfile defaultModels.big;
      profileFiles = {
        big = bigProfile;
        fast = smallProfile;
        plan = bigProfile // {
          plan_mode_reasoning_effort = bigProfile.model_reasoning_effort;
        };
        tiny = mkProfile defaultModels.tiny;
        vision = mkProfile defaultModels.vision;
      };

      catalogSource = fromJSON <| readFile "${pkgs.codex.src}/codex-rs/models-manager/models.json";
      catalogTemplate = findFirst (
        model: model ? model_messages && model.model_messages ? instructions_template
      ) (throw "codex: bundled model catalog has no instructions template") catalogSource.models;

      baseInstructions = catalogTemplate.model_messages.instructions_template;

      modelCatalogEntry =
        priority: model:
        let
          levels = reasoningLevels model;
        in
        {
          slug = model.id;
          display_name = model.name;
          description = null;
          base_instructions = baseInstructions;
          supported_reasoning_levels = map (effort: {
            inherit effort;
            description = "";
          }) levels;
          default_reasoning_level = defaultReasoningLevel levels;
          shell_type = "unified_exec";
          visibility = "list";
          supported_in_api = true;
          inherit priority;
          support_verbosity = false;
          apply_patch_tool_type = "freeform";
          truncation_policy = {
            mode = "tokens";
            limit = 10000;
          };
          context_window = model.context;
          max_context_window = model.context;
          input_modalities =
            if elem "image" model.inputTypes then
              [
                "text"
                "image"
              ]
            else
              [ "text" ];
          experimental_supported_tools = [ ];
          include_skills_usage_instructions = false;
          include_plugin_usage_instructions = false;
          include_apps_usage_instructions = false;
        };

      codexModelCatalog = pkgs.writers.writeJSON "codex-model-catalog.json" {
        models = imap0 modelCatalogEntry config.ai.models;
      };
    in
    {
      ai.secrets = true;

      environment.systemPackages = singleton pkgs.codex;

      hjemModule.files = {
        ".codex/AGENTS.md" = {
          type = "copy";
          source = ./AGENTS.md;
        };

        ".codex/config.toml" = {
          type = "copy";
          generator = pkgs.writers.writeTOML "codex-config.toml";
          value = {
            check_for_update_on_startup = false;
            features.daemon_auto_start = false; # nixpkgs ships no bundled daemon package.

            tui.theme = "gruvbox-dark";

            inherit (smallProfile) model model_provider model_reasoning_effort;
            model_catalog_json = codexModelCatalog;
            review_model = bigProfile.model;
            model_reasoning_summary = "auto";
            hide_agent_reasoning = true;
            agents = {
              default_subagent_model = smallProfile.model;
              default_subagent_reasoning_effort = smallProfile.model_reasoning_effort;
            };

            approval_policy = "on-request";
            sandbox_mode = "workspace-write";
            sandbox_workspace_write.network_access = true;

            features.memories = true;

            model_providers.${providerKey} = {
              inherit (provider) name;

              base_url = provider.baseUrl;
              experimental_bearer_token = provider.apiKey;
            };

          };
        };
      }
      // mapAttrs' (
        name: value:
        nameValuePair ".codex/${name}.config.toml" {
          generator = pkgs.writers.writeTOML "codex-profile-${name}.toml";
          inherit value;
        }
      ) profileFiles;
    };
}
