{
  flake.modules.common.omp =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
    in
    {
      ai.secrets = true;

      shellAliases.omp = "bwrapper omp";

      hjem.extraModule = {
        packages = [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
          pkgs.bun # Gay but needed for some plugins.
          pkgs.node-gyp # ^
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
              providers.commandcode = {
                baseUrl = "https://api.commandcode.ai/provider/v1";
                apiKey = "COMMANDCODE_API_KEY";
                api = "openai-completions";
                models = [
                  {
                    id = "deepseek/deepseek-v4-flash";
                    name = "DeepSeek V4 Flash";
                    reasoning = true;
                    contextWindow = 1000000;
                    maxTokens = 384000;
                  }
                  {
                    id = "deepseek/deepseek-v4-pro";
                    name = "DeepSeek V4 Pro";
                    reasoning = true;
                    contextWindow = 1000000;
                    maxTokens = 384000;
                  }
                  {
                    id = "stepfun/Step-3.5-Flash";
                    name = "Step 3.5 Flash";
                    reasoning = true;
                    contextWindow = 1000000;
                    maxTokens = 384000;
                  }
                  {
                    id = "MiniMaxAI/MiniMax-M3";
                    name = "MiniMax M3";
                    reasoning = true;
                    contextWindow = 1000000;
                    maxTokens = 131072;
                  }
                  {
                    id = "Qwen/Qwen3.7-Flash";
                    name = "Qwen 3.7 Flash";
                    reasoning = true;
                    contextWindow = 1000000;
                    maxTokens = 131072;
                  }
                ];
              };
            };
          };

          ".omp/agent/config.yml" = {
            type = "copy"; # Sometimes needs to write to config.
            generator = pkgs.writers.writeYAML "omp-agent-config.yml";
            value = {
              defaultProvider = "commandcode";
              defaultModel = "deepseek/deepseek-v4-flash";

              # [appearance]
              theme = {
                dark = "dark-gruvbox";
                light = "light-gruvbox";
              };
              symbolPreset = "unicode";
              statusLine = {
                preset = "compact";
                separator = "pipe";
              };
              terminal.showImages = true;
              display = {
                shimmer = "classic";
                showTokenUsage = true;
              };

              # [context]
              contextPromotion = false; # do not upgrade model - compact instead.
              compaction = {
                enabled = true;
                strategy = "context-full";
              };

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
              autoResume = false;
              steeringMode = "all"; # Send all queued messages at once.
              followUpMode = "all";
              interruptMode = "wait";
              power = {
                preventIdleSleep = false;
                preventSystemSleep = false;
                declareUserActive = false;
                preventDisplaySleep = false;
              };
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

              # [internal]
              memories.enabled = false;
              modelProviderOrder = [
                "commandcode"
                "opencode-zen"
              ];
              modelRoles =
                let
                  big = "commandcode/deepseek/deepseek-v4-flash";
                  small = "commandcode/deepseek/deepseek-v4-flash";
                  cheap = "opencode-zen/deepseek-v4-flash-free";
                  vision = "commandcode/Qwen/Qwen3.7-Flash";
                in
                {
                  default = "${small}:auto";
                  smol = "${cheap}:off";
                  slow = "${big}:max";
                  plan = "${big}:max";
                  vision = "${vision}:low";
                  designer = "${vision}:low";
                  commit = "${cheap}:off";
                  task = "${cheap}:low";
                };
              enabledModels = [ ]; # all
              shellPath = getExe pkgs.bash;

              # [memory]
              memory.backend = "off";

              # [model]
              advisor = {
                enabled = false; # Can't choose model yet?
                syncBacklog = 5;
              };
              defaultThinkingLevel = "medium";
              hideThinkingBlock = true;
              personality = "pragmatic";
              retry = {
                maxRetries = 100000;
                maxDelayMs = 600000;
              };

              # [providers]
              secrets.enabled = true;
              providers = {
                webSearch = "auto";
                image = "auto";
                tinyModel = "LFM2-350m";
                tinyModelDevice = "cpu";
                unexpectedStopModel = "qwen3-1.7b";
              };
              exa = {
                enabled = true;
                enableSearch = true;
                enableResearcher = true;
              };

              # [tasks]
              plan.enabled = true;
              goal = {
                enabled = true;
                statusInFooter = true;
              };

              # [tools]
              marketplace.autoUpdate = "notify";
              tools = {
                discoveryMode = "auto";
                approval = { }; # TODO?
              };
              todo = {
                enabled = true;
                reminders = true;
                eager = true;
              };
              find.enabled = true;
              search.enabled = true;
              astGrep.enabled = true;
              irc.enabled = true;
              renderMermaid.enabled = true;
              debug.enabled = true;
              checkpoint.enabled = true;
              fetch.enabled = true;
              github.enabled = true;
              web_search.enabled = true;
              browser.enabled = true;
              async.enabled = true;
              mcp.discoveryMode = true;
              skills = {
                enabled = true;
                enableCodexUser = false;
                enableClaudeUser = false;
                enablePiUser = false;
                enableAgentsUser = false;
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
              dependencies = {
                context-mode = "^1";
                omp-dynamic-context-pruning = "https://github.com/TT432/omp-dynamic-context-pruning";
                ponytail = "https://github.com/DietrichGebert/ponytail";
                "@plannotator/pi-extension" = "^0.25";
              };
            };
          };
        };

        systemd.services.omp-bun-install = {
          description = "bun install for oh-my-pi plugins";
          path = singleton pkgs.bun;
          script = ''
            cd ~/.omp/plugins
            bun install
          '';
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "5s";
          };
          after = singleton "hjem.target";
          wantedBy = singleton "default.target";
        };
      };
    };
}
