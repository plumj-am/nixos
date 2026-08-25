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
                      id = "deepseek/deepseek-v4-flash";
                      name = "DeepSeek V4 Flash";
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
                    }
                    {
                      # TODO: limited input, wait until full release with full context
                      # minimal | low | medium | high | xhigh
                      id = "poolside/laguna-s-2.1-free";
                      name = "Poolside Laguna S 2.1";
                      reasoning = true;
                      contextWindow = 256000;
                      maxTokens = 131072;
                    }
                    {
                      # minimal | low | medium | high | xhigh
                      id = "meta/muse-spark-1.2-contributor";
                      name = "Meta Muse Spark 1.2";
                      reasoning = true;
                      thinking = {
                        minLevel = "minimal";
                        maxLevel = "xhigh";
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
                    {
                      # minimal | low | medium | high
                      id = "stealth/ox-alpha";
                      name = "Ox Alpha";
                      reasoning = true;
                      input = [
                        "text"
                      ];
                      cost = {
                        input = 0;
                        output = 0;
                        cacheRead = 0;
                        cacheWrite = 0;
                      };
                      contextWindow = 1048576;
                      maxTokens = 131072;
                      compat = {
                        supportsReasoningEffort = false;
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
                big = "${activeSub}/stealth/ox-alpha:high";
                small = "${activeSub}/stealth/ox-alpha:high";
                cheap = "${activeSub}/stealth/ox-alpha:high";
                vision = "${activeSub}/meta/muse-spark-1.2-contributor:low";

                bigFallback = [
                  "opencode-zen/laguna-s-2.1-free:xhigh"
                  "${activeSub}/deepseek/deepseek-v4-flash:xhigh"
                  "${activeSub}/meta/muse-spark-1.2-contributor:xhigh"
                  "nvidia/deepseek-ai/deepseek-v4-flash-0731:auto"
                ];
                smallFallback = [
                  "opencode-zen/laguna-s-2.1-free:high"
                  "opencode-zen/deepseek-v4-flash-free:auto"
                  "${activeSub}/deepseek/deepseek-v4-flash:high"
                  "${activeSub}/meta/muse-spark-1.2-contributor:medium"
                  "nvidia/deepseek-ai/deepseek-v4-flash-0731:auto"
                ];
                cheapFallback = [
                  "opencode-zen/laguna-s-2.1-free:low"
                  "opencode-zen/deepseek-v4-flash-free:high"
                  "${activeSub}/deepseek/deepseek-v4-flash:high"
                  "${activeSub}/meta/muse-spark-1.2-contributor:low"
                  "nvidia/deepseek-ai/deepseek-v4-flash-0731:auto"
                ];
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
                git.enabled = false; # only affects status bar (using jj anyway)

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
                  modelFallback = true;
                  fallbackRevertPolicy = "cooldown-expiry";
                  maxRetries = 100000;
                  maxDelayMs = 600000;
                  fallbackChains = {
                    default = smallFallback;
                    smol = cheapFallback;
                    slow = bigFallback;
                    advisor = cheapFallback;
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
                omp-dynamic-context-pruning = "https://github.com/plumj-am/omp-dynamic-context-pruning";
                ponytail = "https://github.com/DietrichGebert/ponytail";
                "@plannotator/pi-extension" = "^0.26";
                caveman = "https://github.com/JuliusBrussee/caveman";
              };
            };
          };

          ".omp/agent/dcp.json" = {
            type = "copy";
            generator = pkgs.writers.writeJSON "omp-agent-dcp.json";
            value = {
              enabled = true;

              minContextLimit = 50000;
              maxContextLimit = 200000;

              showCompression = true;

              experimental.allowSubAgents = true;
            };
          };
        };

        xdg.config.files."ponytail/config.json" = {
          generator = pkgs.writers.writeJSON "ponytail-config.json";
          value.defaultMode = "ultra";
        };

        systemd.services.omp-install-plugins-skills = {
          description = "automatic plugin and skill install for oh-my-pi";
          after = singleton "nixos-rebuild-switch-to-configuration.target";
          wantedBy = singleton "default.target";
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "120s";
          };

          path = [
            pkgs.bash
            pkgs.gcc
            pkgs.gitMinimal
            pkgs.gnumake
            pkgs.nodejs
            pkgs.node-gyp
          ];
          environment.PYTHON = getExe pkgs.python3;
          script = # sh
            ''
              cd ~/.omp/plugins
              rm --force bun.lock node_modules/ || true
              ${getExe pkgs.bun} install --force --refresh

              echo "skills add mattpocock/skills"
              ${getExe pkgs.skills} add mattpocock/skills \
                --skill grilling \
                --skill grill-me \
                --skill grill-with-docs \
                --yes \
                --agent universal \
                --global
            '';
        };
      };
    };
}
