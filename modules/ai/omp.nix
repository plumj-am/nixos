{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.omp;
  flake.modules.common.omp =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets)
        mapAttrs
        mapAttrs'
        nameValuePair
        optionalAttrs
        ;
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (config.ai) defaultModels;
      inherit (config.users.users.jam) home;

      providerKey = config.ai.providers.headroomVineProxy.name;

      models = mapAttrs (_: m: "${providerKey}/${m}") defaultModels;
    in
    {
      ai.secrets = true;

      hjem.extraModule = {
        packages = [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
          pkgs.bun # Gay but needed for some plugins.
          pkgs.node-gyp # ^
          pkgs.rtk # Rewrites bash commands; install service drops in its extension.
        ];

        # Another that doesn't follow XDG spec, amazing...
        files = {
          ".omp/agent/AGENTS.md" = {
            type = "copy";
            source = ./AGENTS.md;
          };

          ".omp/agent/models.yml" = {
            generator = pkgs.writers.writeYAML "omp-agent-models.yml";
            value = {
              providers =
                let
                  modelAttrRenames = {
                    inputTypes = "input";
                    context = "contextWindow";
                    maxOutput = "maxTokens";
                    costPerMillion = "cost";
                  };

                  models =
                    config.ai.models
                    |> map (
                      model: mapAttrs' (name: value: nameValuePair (modelAttrRenames.${name} or name) value) model
                    );
                in
                config.ai.providers
                |> mapAttrs' (
                  _: provider:
                  nameValuePair provider.name (
                    {
                      inherit (provider) baseUrl;
                    }
                    // optionalAttrs (provider.type == "openai-compatible") { api = "openai-completions"; }
                    // (
                      if provider ? apiKey then
                        { inherit (provider) apiKey; }
                      else
                        optionalAttrs (provider ? auth) { inherit (provider) auth; }
                    )
                    // (
                      if provider ? discoveryType then
                        { discovery.type = provider.discoveryType; }
                      else
                        { inherit models; }
                    )
                  )
                );
            };
          };

          ".omp/agent/config.yml" = {
            type = "copy"; # Sometimes needs to write to config.
            generator = pkgs.writers.writeYAML "omp-agent-config.yml";
            value = {
              # [appearance]
              theme = {
                dark = "dark";
                light = "light";
              };
              symbolPreset = "unicode";
              statusLine = {
                preset = "compact";
                separator = "pipe";
                transparent = true;
              };
              terminal.showImages = true;
              display = {
                shimmer = "classic";
                showTokenUsage = true;
                cacheMissMarker = true;
              };
              tui.renderMermaid = true;

              # [context]
              contextPromotion.enabled = false; # do not upgrade model - compact instead.
              compaction.enabled = true;

              # [editing]
              lsp = {
                enabled = true;
                formatOnWrite = false;
                diagnosticsOnWrite = true;
                diagnosticsOnEdit = false;
                diagnosticsDeduplicate = true;
              };
              eval = {
                js = true;
                py = true;
              };

              # [interaction]
              autoResume = true;
              steeringMode = "all"; # Send all queued messages at once.
              followUpMode = "all";
              interruptMode = "wait";
              autocompleteMaxVisible = 20;
              power.sleepPrevention = "off";
              startup = {
                quiet = true;
                setupWizard = false;
                checkUpdate = false;
              };
              ask = {
                timeout = 0;
                notify = "on";
              };
              features.unexpectedStopDetection = true;
              git.enabled = true; # only affects status bar (replaced by pi-jujutsu plugin)

              # [internal]
              memories.enabled = false;
              modelProviderOrder = singleton providerKey;
              modelRoles = with models; {
                default = small;
                smol = small;
                slow = big;
                advisor = small;
                plan = small;
                inherit vision;
                designer = vision;
                commit = small;
                task = small;
                tiny = small;
              };
              enabledModels = [ ]; # all
              shellPath = getExe pkgs.bash;

              # [memory]
              memory.backend = "mnemopi";
              mnemopi = {
                scoping = "per-project-tagged";
                dbPath = "${home}/.omp/agent/memories/mnemopi/mnemopi.db";

                embeddingVariant = "en";
                polyphonicRecall = true;
                practiveLinking = true;
                enhancedRecall = true;
              };

              # [model]
              advisor = {
                enabled = true;
                syncBacklog = 5;
              };
              defaultThinkingLevel = "medium";
              hideThinkingBlock = true;
              personality = "pragmatic";
              textVerbosity = "low";
              retry = {
                modelFallback = false;
                fallbackRevertPolicy = "cooldown-expiry";
                waitForUsageReset = true;
                maxRetries = 200;
                maxDelayMs = 0;
                fallbackChains = { };
              };

              # [providers]
              secrets.enabled = true;
              providers = {
                tinyModel = "LFM2-350m";
                tinyModelDevice = "cpu";
                unexpectedStopModel = "qwen3-1.7b";
              };
              exa.enabled = true;

              # [tasks]
              plan.enabled = true;
              goal = {
                enabled = true;
                statusInFooter = true;
              };
              task.eager = "always"; # sub-agent delegation

              # [tools]
              marketplace.autoUpdate = "notify";
              tools.approval = { }; # TODO?
              todo = {
                enabled = true;
                reminders = true;
                eager = "always";
              };
              astGrep.enabled = true;
              debug.enabled = true;
              checkpoint.enabled = true;
              fetch.enabled = true;
              github.enabled = true;
              web_search.enabled = true;
              browser.enabled = true;
              async.enabled = true;
              security.enabled = true;
              skills = {
                enabled = true;
                enableCodexUser = false;
                enableClaudeUser = false;
                enablePiUser = true;
                enableAgentsUser = true;
                enableClaudeProject = false;
                enablePiProject = false;
                enableAgentsProject = false;
              };

              # [shell]
              bash = {
                enabled = true;
                autoBackground.enabled = true;
              };
              bashInterceptor.enabled = true;
            };
          };

          ".omp/plugins/package.json" = {
            type = "copy";
            generator = pkgs.writers.writeJSON "omp-plugins-package.json";
            value = {
              name = "omp-plugins";
              private = true;
              # Bun blocks install scripts of unlisted deps; node-pty and the
              # others need theirs to build for Linux.
              trustedDependencies = [
                "@google/genai"
                "better-sqlite3"
                "node-pty"
                "onnxruntime-node"
                "protobufjs"
                "sharp"
              ];
              dependencies = {
                "@plannotator/pi-extension" = "^0.26";
                pi-jujutsu = "^0.1";
                pi-jj-git-align = "^0.1";
              };
            };
          };

          ".omp/agent/extensions/theme.ts".source =
            self.packages.${pkgs.stdenv.hostPlatform.system}.omp-theme;
        };
      };
    };
}
