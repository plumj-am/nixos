{
  flake.modules.common.pi =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
    in
    {
      age.secrets = {
        opencodeGoKey = {
          rekeyFile = ../../../secrets/opencode-go-key.age;
          owner = "jam";
          group = "users";
          mode = "600";
        };
        nvidiaNimKey = {
          rekeyFile = ../../../secrets/nvidia-nim-key.age;
          owner = "jam";
          group = "users";
          mode = "600";
        };
        codestralKey = {
          rekeyFile = ../../../secrets/codestral-key.age;
          owner = "jam";
          group = "users";
          mode = "600";
        };
        llm7Key = {
          rekeyFile = ../../../secrets/llm7-key.age;
          owner = "jam";
          group = "users";
          mode = "600";
        };
        openrouterKey = {
          rekeyFile = ../../../secrets/openrouter-key.age;
          owner = "jam";
          group = "users";
          mode = "600";
        };
        ollamaKey = {
          rekeyFile = ../../../secrets/ollama-key.age;
          owner = "jam";
          group = "users";
          mode = "600";
        };
        sambanovaKey = {
          rekeyFile = ../../../secrets/sambanova-key.age;
          owner = "jam";
          group = "users";
          mode = "600";
        };
      };

      shellAliases.pi = "bwrapper pi";

      hjem.extraModule =
        { osConfig, ... }:
        {
          packages = singleton inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

          # Another that doesn't follow XDG spec, amazing...
          files = {
            ".pi/agent/AGENTS.md" = {
              type = "copy";
              source = ../AGENTS.md;
            };

            ".pi/agent/auth.json" = {
              generator = pkgs.writers.writeJSON "pi-agent-auth.json";
              type = "copy"; # I think pi auth requires this and 600 mode.
              permissions = "600";
              value = {
                opencode-go = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.opencodeGoKey.path}";
                };
                nvidia-nim = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.nvidiaNimKey.path}";
                };
                codestral = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.codestralKey.path}";
                };
                llm7 = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.llm7Key.path}";
                };
                openrouter = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.openrouterKey.path}";
                };
                ollama = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.ollamaKey.path}";
                };
                sambanova = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.sambanovaKey.path}";
                };
              };
            };

            ".pi/free.json" = {
              generator = pkgs.writers.writeJSON "pi-free.json";
              type = "copy";
              permissions = "600";
              value = {
                cerebras_api_key = "";
                codestral_api_key = "";
                crofai_api_key = "";
                deepinfra_api_key = "";
                groq_api_key = "";
                hf_token = "";
                llm7_api_key = "";
                mistral_api_key = "";
                nvidia_api_key = "";
                ollama_api_key = "";
                sambanova_api_key = "";
                xai_api_key = "";
                zenmux_api_key = "";

                free_only = true;
                cline_show_paid = false;
                codestral_show_paid = false;
                crofai_show_paid = false;
                deepinfra_show_paid = false;
                kilo_free_only = false;
                kilo_show_paid = false;
                llm7_show_paid = false;
                nvidia_show_paid = true;
                ollama_show_paid = false;
                opencode_show_paid = false;
                openrouter_show_paid = false;
                sambanova_show_paid = false;
                zenmux_show_paid = false;

                hidden_models = [
                  "nvidia/mistralai/mistral-medium-3-instruct"
                ];
              };
            };

            ".pi/agent/models.json" = {
              generator = pkgs.writers.writeJSON "pi-agent-config.json";
              value =
                let
                  mkLocalProvider =
                    baseUrl: rest:
                    {
                      inherit baseUrl;
                      api = "openai-completions";
                      apiKey = "dummy";
                    }
                    // rest;
                in
                {
                  providers = {
                    llama-cpp = mkLocalProvider "http://localhost:11435/v1" {
                      models = [
                        {
                          id = "unsloth/Qwen3.6-35B-A3B:UD-IQ3_XXS";
                          contextWindow = 131072;
                          compat.supportsDeveloperRole = false;
                        }
                      ];
                    };
                  };
                };
            };

            # To test later but idk why it has to be via MCP...
            # ".pi/agent/mcp.json" = {
            #   generator = pkgs.writers.writeJSON "pi-agent-config.json";
            #   value = {
            #     mcpServers = {
            #       context-mode = {
            #         command = "npx";
            #         args = [
            #           "tsx"
            #           "/home/jam/.pi/agent/git/github.com/context-mode/src/server.ts"
            #         ];
            #       };
            #     };
            #   };
            # };

            ".pi/agent/settings.json" = {
              type = "copy"; # Sometimes needs to write to config.
              generator = pkgs.writers.writeJSON "pi-agent-config.json";
              value = {
                defaultProvider = "opencode-go";
                defaultModel = "kimi-k2.6";
                enabledModels = [
                  "*kimi-k2*"
                  "*qwen3.*"
                  "*minimax-m2.7*"
                  "*mimo-v2.5*"
                  "*deepseek-v4*"
                  "*grok*"
                  "*codestral*"
                  "*nemotron-3-super*"
                  "*glm-5*"
                  "*glm5*"
                  "*gpt-oss-120b*"
                  "*gpt-oss:120b*"

                  "unsloth/Qwen3.6-35B-A3B:UD-IQ3_XXS"
                ];

                quietStartup = true;
                hideThinkingBlock = true;

                # Send all queued messages at once.
                steeringMode = "all";
                followUpMode = "all";

                enableInstallTelemetry = false;
                editorPaddingX = 1;

                shellPath = getExe pkgs.bash;

                packages = [
                  {
                    source = "git:github.com/apmantza/pi-free";
                    extensions = [ "index.ts" ];
                    themes = [ ];
                    skills = [ ];
                  }
                  {
                    source = "git:github.com/nicobailon/pi-interview-tool";
                    extensions = [ "index.ts" ];
                    themes = [ ];
                    skills = [ ];
                  }
                  {
                    source = "git:github.com/samfoy/pi-memory";
                    extensions = [ "index.ts" ];
                    themes = [ ];
                    skills = [ ];
                  }
                  {
                    source = "git:github.com/netresearch/context7-skill";
                    extensions = [ ];
                    themes = [ ];
                    skills = [ "context7" ];
                  }
                  {
                    source = "git:github.com/mitsuhiko/agent-stuff";
                    extensions = [
                      "btw.ts"
                      "context.ts"
                      "loop.ts"
                      "multi-edit.ts"
                    ];
                    themes = [ ];
                    skills = [ ];
                  }
                ];
              };
            };
            # Yes, I could just `".pi/agent/extensions".source = ./extensions`
            # but this way I can add and remove easily.
            ".pi/agent/extensions/system-theme.ts".source = ./extensions/system-theme.ts;
            ".pi/agent/extensions/permissions.ts".source = ./extensions/permissions.ts;
            ".pi/agent/extensions/plan-mode.ts".source = ./extensions/plan-mode.ts;
            ".pi/agent/extensions/read-only-mode.ts".source = ./extensions/read-only-mode.ts;
            ".pi/agent/extensions/zellij-attention.ts".source = ./extensions/zellij-attention.ts;
            ".pi/agent/extensions/caveman.ts".source = ./extensions/caveman.ts;
            ".pi/agent/extensions/tps-status.ts".source = ./extensions/tps-status.ts;

            ".pi/agent/skills/caveman".source = ./skills/caveman;
            ".pi/agent/skills/gh-grep".source = ./skills/gh-grep; # Taken from <https://github.com/huynguyen03dev/opencode-setup/tree/main/skills/gh-grep>

            ".pi/agent/agents".source = ./agents;
          };
        };
    };
}
