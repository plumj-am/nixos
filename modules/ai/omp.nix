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
      inherit (config.ai.subs.commandcode) active;

      activeSub = "commandcode-${toString active}";
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
              providers = {
                ${activeSub} = {
                  baseUrl = "https://api.commandcode.ai/provider/v1";
                  apiKey = "!cat ${secrets."${activeSub}-key".path}";
                  api = "openai-completions";
                  models = [
                    {
                      # high | xhigh
                      id = "deepseek/deepseek-v4.1-flash";
                      name = "DeepSeek V4.1 Flash";
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
                      cost = {
                        input = 0.22;
                        output = 0.66;
                        cacheRead = 0.007;
                        cacheWrite = 0;
                      };
                    }
                    {
                      # TODO: limited input, wait until full release with full context
                      # minimal | low | medium | high | xhigh
                      id = "poolside/laguna-s-2.1-free";
                      name = "Poolside Laguna S 2.1 free";
                      reasoning = true;
                      contextWindow = 256000;
                      maxTokens = 131072;
                      cost = {
                        input = 0;
                        output = 0;
                        cacheRead = 0;
                        cacheWrite = 0;
                      };
                    }
                    {
                      id = "meituan/LongCat-2.0:free";
                      name = "Meituan LongCat 2.0 free";
                      reasoning = true;
                      contextWindow = 1048576;
                      maxTokens = 131072;
                      cost = {
                        input = 0;
                        output = 0;
                        cacheRead = 0;
                        cacheWrite = 0;
                      };
                    }
                    {
                      id = "Qwen/Qwen3.8-Flash";
                      name = "Qwen3.8 Flash";
                      reasoning = true;
                      thinking = {
                        minLevel = "low";
                        maxLevel = "xhigh";
                        mode = "effort";
                      };
                      contextWindow = 1048576;
                      maxTokens = 131072;
                      input = [
                        "text"
                        "image"
                      ];
                      cost = {
                        input = 0.16;
                        output = 0.47;
                        cacheRead = 0.016;
                        cacheWrite = 0;
                      };
                    }
                    {
                      # minimal | low | medium | high | xhigh
                      id = "meta/muse-spark-1.3-contributor";
                      name = "Meta Muse Spark 1.3 Contributor";
                      reasoning = true;
                      thinking = {
                        minLevel = "minimal";
                        maxLevel = "max";
                        mode = "effort";
                      };
                      input = [
                        "text"
                        "image"
                      ];
                      cost = {
                        input = 0.1;
                        output = 0.2;
                        cacheRead = 0.002;
                        cacheWrite = 0;
                      };
                      contextWindow = 1048576;
                      maxTokens = 131072;
                      compat = {
                        supportsReasoningEffort = true;
                        supportsToolChoice = false;
                      };
                    }
                  ];
                };

                "llama.cpp" = {
                  baseUrl = "http://127.0.0.1:11435";
                  api = "openai-completions";
                  auth = "none";
                  discovery.type = "llama.cpp";
                };

                nvidia.apiKey = "!cat ${secrets.nvidia-nim-key.path}";

                # Static defs so these resolve at launch before the remote
                # opencode-zen catalog fetch completes. laguna-s-2.1-free is
                # NOT in omp's catalog so need to add stuff manually.
                opencode-zen = {
                  baseUrl = "https://opencode.ai/zen/v1";
                  apiKey = "!cat ${secrets.opencode-go-key.path}";
                  api = "openai-completions";
                  models = [
                    {
                      # minimal | low | medium | high | xhigh
                      id = "laguna-s-2.1-free";
                      name = "Poolside Laguna S 2.1";
                      reasoning = true;
                      contextWindow = 256000;
                      maxTokens = 131072;
                    }
                    {
                      # high | xhigh
                      id = "deepseek-v4-flash-free";
                    }
                  ];
                };
              };
            };
          };

          ".omp/agent/config.yml" = {
            type = "copy"; # Sometimes needs to write to config.
            generator = pkgs.writers.writeYAML "omp-agent-config.yml";
            value =
              let
                big = "${activeSub}/deepseek/deepseek-v4.1-flash:max";
                small = "${activeSub}/deepseek/deepseek-v4.1-flash:low";
                cheap = "${activeSub}/meituan/LongCat-2.0:free:auto";
                vision = "${activeSub}/Qwen/Qwen3.8-Flash:low";
              in
              {
                # [appearance]
                theme = {
                  dark = "dark-gruvbox";
                  light = "light-gruvbox";
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
                autoResume = false;
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
                modelProviderOrder = [
                  activeSub
                  "opencode-zen"
                ];
                modelRoles = {
                  default = small;
                  smol = cheap;
                  slow = big;
                  advisor = cheap;
                  plan = big;
                  inherit vision;
                  designer = vision;
                  commit = cheap;
                  task = cheap;
                  tiny = cheap;
                };
                enabledModels = [ ]; # all
                shellPath = getExe pkgs.bash;

                # [memory]
                memory.backend = "off";

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
                  maxRetries = 100000;
                  maxDelayMs = 600000;
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

          ".omp/agent/extensions/zellij-attention-hook.ts".text = # ts
            ''
              // oh-my-pi extension: flag the zellij tab via zellij-attention.
              // ⏳ waiting = ask tool (blocked on user), ✅ completed = terminal settle.
              // https://github.com/KiryuuLight/zellij-attention

              import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

              export default function (pi: ExtensionAPI): void {
                const paneId = process.env.ZELLIJ_PANE_ID;
                const pipe = (state: string) =>
                  void pi
                    .exec("zellij", [
                      "pipe",
                      "--name",
                      `zellij-attention::''${state}::''${paneId}`,
                    ])
                    .catch(() => {});

                pi.on("tool_call", (event) => {
                  if (!paneId) return;
                  if (event.toolName === "ask") pipe("waiting");
                });

                pi.on("agent_end", (event, ctx) => {
                  if (!paneId) return;
                  if (event.willContinue || ctx.hasPendingMessages()) return;
                  pipe("completed");
                });
              }
            '';
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
                "context-mode"
                "node-pty"
                "onnxruntime-node"
                "protobufjs"
                "sharp"
              ];
              dependencies = {
                context-mode = "^1";
                ponytail = "https://github.com/DietrichGebert/ponytail";
                "@plannotator/pi-extension" = "^0.26";
                caveman = "https://github.com/JuliusBrussee/caveman";
                pi-jujutsu = "^0.1";
                pi-jj-git-align = "^0.1";
              };
            };
          };
        };

        xdg.config.files."ponytail/config.json" = {
          generator = pkgs.writers.writeJSON "ponytail-config.json";
          value.defaultMode = "ultra";
        };
      };
    };
}
