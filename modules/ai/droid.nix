{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.droid;
  flake.modules.common.droid =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) singleton;
      inherit (lib.trivial) const flip;
      inherit (config.users.users.jam) home;

      providerKey = "vine";
      vineBaseUrl = "http://127.0.0.1:8022/v1";

      big = "custom:${providerKey}/xiaomi/mimo-v2.6-pro";
      small = "custom:${providerKey}/xiaomi/mimo-v2.6-flash";

      mkVineModel =
        index:
        {
          id,
          displayName,
          maxOutputTokens ? 262144,
          noImageSupport ? true,
        }:
        {
          inherit
            displayName
            index
            maxOutputTokens
            noImageSupport
            ;
          model = id;
          id = "custom:${id}";
          baseUrl = vineBaseUrl;
          provider = "generic-chat-completion-api";
        };
    in
    {
      ai.secrets = true;

      environment.systemPackages =
        singleton
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.droid;

      hjemModule = {
        files.".factory/settings.json" = {
          type = "copy";
          generator = pkgs.writers.writeJSON "factory-settings.json";
          value = {
            customModels = [
              (mkVineModel 1 {
                id = "${providerKey}/xiaomi/mimo-v2.6-flash";
                displayName = "Mimo v2.6 Flash";
              })
              (mkVineModel 2 {
                id = "${providerKey}/xiaomi/mimo-v2.6-pro";
                displayName = "Mimo v2.6 Pro";
              })
              (mkVineModel 3 {
                id = "${providerKey}/deepseek/deepseek-v4.1-flash";
                displayName = "Deepseek v4.1 Flash";
                maxOutputTokens = 384000;
                noImageSupport = true;
                # extraArgs.thinking.type = "enabled";
              })
              (mkVineModel 4 {
                id = "${providerKey}/meta/muse-spark-1.3-contributor";
                displayName = "Muse Spark 1.3";
                maxOutputTokens = 131072;
              })
            ];

            model = small;
            reasoningEffort = "medium";

            sessionDefaultSettings = {
              interactionMode = "auto";
              autonomyLevel = "medium";
              model = small;
              reasoningEffort = "medium";
            };

            subagentAutonomyLevel = "inherit";
            subagentModelSettings = {
              lightModel = small;
              mediumModel = small;
              heavyModel = big;
            };

            compactionTokenLimit = 250000;

            diffMode = "github";
            toolResultDisplay = "expanded";
            showTokenUsageIndicator = true;
            showThinkingInMainView = false;
            logoAnimation = "off";
            theme = "auto";
            nerdFont = true;

            completionSound = "fx-ok01";
            awaitingInputSound = "fx-ack01";
            soundFocusMode = "focused";
            subagentSounds = "quiet";

            enableDroidShield = true;
            commandAllowlist = config.ai.commands.bash.allow;
            commandDenylist = [ ];
            commandBlocklist = [ ];

            includeCoAuthoredByDroid = false;
            cloudSessionSync = false;

            llmRequestTimeout = 120000;
            blockOnMcpLoad = false;
            # worktreeDirectory = "~/.factory/worktrees";

            trustedFolders = flip genAttrs (const { trustedAt = "1970-01-01T00:00:00.000Z"; }) [
              "${home}/nixos"
              "${home}/projects"
            ];
          };
        };
      };
    };
}
