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

      environment.systemPackages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
        pkgs.bun # Gay but needed for some plugins.
        pkgs.node-gyp # ^
        pkgs.rtk # Rewrites bash commands; install service drops in its extension.
      ];

      hjemModule = {
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
              theme.dark = "dark";
              theme.light = "light";
              symbolPreset = "unicode";

              statusLine.preset = "compact";
              statusLine.separator = "pipe";
              statusLine.transparent = true;

              terminal.showImages = true;
              display.shimmer = "classic";
              display.showTokenUsage = true;
              display.cacheMissMarker = true;
              tui.renderMermaid = true;
              read.renderMarkdown = true;

              enabledModels = [ ]; # all
              modelProviderOrder = singleton providerKey;
              modelRoles = with models; {
                default = small;
                smol = small;
                slow = big;
                advisor = small;
                plan = big;
                inherit vision;
                designer = vision;
                commit = small;
                task = tiny;
                tiny = tiny;
                judge = decision;
              };

              providers.tinyModel = "LFM2-350m";
              providers.tinyModelDevice = "cpu";
              providers.unexpectedStopModel = "qwen3-1.7b";

              advisor.enabled = true;
              advisor.syncBacklog = 5;

              retry.modelFallback = false;
              retry.fallbackRevertPolicy = "cooldown-expiry";
              retry.waitForUsageReset = true;
              retry.maxRetries = 200;
              retry.maxDelayMs = 0;
              retry.fallbackChains = {
                judge = [
                  "@tiny"
                  "@smol"
                ];
              };

              contextPromotion.enabled = false; # do not upgrade model - compact instead.
              compaction.enabled = true;

              autoResume = true;
              features.unexpectedStopDetection = true;

              steeringMode = "all"; # Send all queued messages at once.
              followUpMode = "all";
              interruptMode = "wait";

              personality = "pragmatic";
              textVerbosity = "low";
              defaultThinkingLevel = "medium";
              hideThinkingBlock = true;

              memories.enabled = true;
              memory.backend = "mnemopi";
              mnemopi.scoping = "per-project-tagged";
              mnemopi.dbPath = "${home}/.omp/agent/memories/mnemopi/mnemopi.db";
              mnemopi.embeddingVariant = "en";
              mnemopi.polyphonicRecall = true;
              mnemopi.practiveLinking = true;
              mnemopi.enhancedRecall = true;
              autolearn.enabled = true;
              autolearn.autoContinue = true;

              task.eager = "always"; # sub-agent delegation

              ask.timeout = 0;
              ask.notify = "on";
              error.notify = "on";

              tools.approval = { }; # TODO?

              edit.autoRepair.enabled = true;

              shellPath = getExe pkgs.bash;
              bash.enabled = true;
              bash.autoBackground.enabled = true;
              bashInterceptor.enabled = true;

              eval.autoBackground.enabled = true;
              eval.js = true;
              eval.py = true;
              python.interpreter = getExe pkgs.python3;

              astGrep.enabled = true;
              debug.enabled = true;
              checkpoint.enabled = true;
              fetch.enabled = true;

              git.enabled = true; # only affects status bar (replaced by pi-jujutsu plugin)
              github.enabled = true;

              web_search.enabled = true;
              exa.enabled = true;
              browser.enabled = true;

              async.enabled = true;
              security.enabled = true;
              secrets.enabled = true;

              plan.enabled = true;
              goal.enabled = true;
              goal.statusInFooter = true;

              todo.enabled = true;
              todo.reminders = true;
              todo.eager = "always";

              ida.python = "${getExe pkgs.python3}";
              ida.installDir = ""; # TODO?

              lsp.enabled = true;
              lsp.formatOnWrite = false;
              lsp.diagnosticsOnWrite = true;
              lsp.diagnosticsOnEdit = false;
              lsp.diagnosticsDeduplicate = true;

              skills.enabled = true;
              skills.enableCodexUser = false;
              skills.enableClaudeUser = false;
              skills.enablePiUser = true;
              skills.enableAgentsUser = true;
              skills.enableClaudeProject = false;
              skills.enablePiProject = false;
              skills.enableAgentsProject = false;

              autocompleteMaxVisible = 20;

              startup.quiet = true;
              startup.setupWizard = false;
              startup.checkUpdate = false;

              marketplace.autoUpdate = "notify";

              power.sleepPrevention = "off";
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

          ".omp/agent/extensions/grove-goal.ts".source =
            self.packages.${pkgs.stdenv.hostPlatform.system}.omp-grove-goal;
        };
      };
    };
}
