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
      inherit (lib.attrsets)
        genAttrs
        mapAttrs
        optionalAttrs
        ;
      inherit (lib.lists)
        elem
        imap1
        singleton
        ;
      inherit (lib.trivial) const flip;
      inherit (config.ai) defaultModels;
      inherit (config.users.users.jam) home;

      providerKey = config.ai.providers.headroomVineProxy.name;

      models = mapAttrs (_: m: "custom:${providerKey}/${m}") defaultModels;
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
            customModels =
              config.ai.models
              |> imap1 (
                index: model:
                let
                  provider = config.ai.providers.headroomVineProxy;
                  fullName = "${provider.name}/${model.id}";
                in
                {
                  inherit index;
                  inherit (provider) baseUrl;
                  displayName = model.name;
                  maxOutputTokens = model.maxOutput;
                  noImageSupport = !(elem "image" model.inputTypes);
                  provider = "generic-chat-completion-api";
                  model = model.id;
                  id = "custom:${fullName}";
                }
                // optionalAttrs (provider ? apiKey) { inherit (provider) apiKey; }
              );

            model = models.small;
            reasoningEffort = "medium";

            sessionDefaultSettings = {
              interactionMode = "auto";
              autonomyLevel = "medium";
              model = models.small;
              reasoningEffort = "medium";
            };

            subagentAutonomyLevel = "inherit";
            subagentModelSettings = with models; {
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
