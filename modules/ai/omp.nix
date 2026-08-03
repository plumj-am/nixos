{
  flake.modules.common.omp =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
      inherit (config.sops) secrets;
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
                apiKey = "!cat ${secrets.command-code-key.path}";
                api = "openai-completions";
                models =
                  let
                    mkDeepSeekModel =
                      { id, name }:
                      singleton {
                        inherit id name;
                        reasoning = true;
                        thinking = {
                          minLevel = "high";
                          maxLevel = "xhigh";
                          mode = "effort";
                        };
                        input = singleton "text";
                        contextWindow = 1000000;
                        maxTokens = 384000;
                        compat = {
                          supportsDeveloperRole = false;
                          supportsReasoningEffort = true;
                          maxTokensField = "max_tokens";
                          reasoningEffortMap = {
                            low = "high"; # lowest available for V4 models
                            high = "high";
                            xhigh = "max";
                          };
                          supportsToolChoice = false;
                          requiresReasoningContentForToolCalls = true;
                          requiresAssistantContentForToolCalls = true;
                          extraBody.thinking.type = "enabled";
                        };
                      };
                  in
                  mkDeepSeekModel {
                    id = "deepseek/deepseek-v4-flash";
                    name = "DeepSeek V4 Flash";
                  }
                  ++ mkDeepSeekModel {
                    id = "deepseek/deepseek-v4-pro";
                    name = "DeepSeek V4 Pro";
                  }
                  ++ [
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
                    # TODO: limited input, wait until full release with full context
                    {
                      id = "poolside/laguna-s-2.1-free";
                      name = "Poolside Laguna S 2.1";
                      reasoning = true;
                      contextWindow = 256000;
                      maxTokens = 131072;
                    }
                  ];
              };

              # Static defs so these resolve at launch before the remote
              # opencode-zen catalog fetch completes. laguna-s-2.1-free is
              # NOT in omp's catalog so need to add stuff manually.
              providers.opencode-zen = {
                baseUrl = "https://opencode.ai/zen/v1";
                apiKey = "!cat ${secrets.opencode-go-key.path}";
                api = "openai-completions";
                models = [
                  {
                    id = "laguna-s-2.1-free";
                    name = "Poolside Laguna S 2.1";
                    reasoning = true;
                    contextWindow = 256000;
                    maxTokens = 131072;
                  }
                  { id = "deepseek-v4-flash-free"; }
                ];
              };
            };
          };

          ".omp/agent/config.yml" = {
            type = "copy"; # Sometimes needs to write to config.
            generator = pkgs.writers.writeYAML "omp-agent-config.yml";
            value =
              let
                big = "opencode-zen/laguna-s-2.1-free";
                small = "opencode-zen/laguna-s-2.1-free";
                cheap = "opencode-zen/laguna-s-2.1-free";
                vision = "commandcode/Qwen/Qwen3.7-Flash";

                bigFallback = [
                  "commandcode/deepseek/deepseek-v4-flash"
                  "commandcode/minimaxai/minimax-m3"
                ];
                smallFallback = [
                  "opencode-zen/deepseek-v4-flash-free"
                  "commandcode/deepseek/deepseek-v4-flash"
                ];
                cheapFallback = [
                  "opencode-zen/deepseek-v4-flash-free"
                  "commandcode/stepfun/step-3.5-flash"
                  "commandcode/deepseek/deepseek-v4-flash"
                ];
              in
              {
                defaultProvider = "opencode-zen";
                defaultModel = "laguna-s-2.1-free";

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
                modelRoles = {
                  default = "${small}:high";
                  smol = "${cheap}:off";
                  slow = "${big}:max";
                  advisor = "${big}:max";
                  plan = "${big}:max";
                  vision = "${vision}:low";
                  designer = "${vision}:low";
                  commit = "${cheap}:off";
                  task = "${cheap}:low";
                  tiny = "${cheap}:low";
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
                  modelFallback = true;
                  fallbackRevertPolicy = "cooldown-expiry";
                  maxRetries = 100000;
                  maxDelayMs = 600000;
                  fallbackChains = {
                    default = smallFallback;
                    smol = cheapFallback;
                    slow = bigFallback;
                    advisor = bigFallback;
                    plan = bigFallback;
                    vision = [ ]; # TODO: add another vision model
                    designer = [ ];
                    commit = cheapFallback;
                    task = cheapFallback;
                    tiny = cheapFallback;
                  };
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
                caveman = "https://github.com/JuliusBrussee/caveman";
              };
            };
          };
        };

        xdg.config.files."ponytail/config.json" = {
          generator = pkgs.writers.writeJSON "ponytail-config.json";
          value.defaultMode = "ultra";
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
