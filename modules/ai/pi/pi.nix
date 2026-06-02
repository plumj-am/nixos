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
        commandcodeKey = {
          rekeyFile = ../../../secrets/commandcode-key.age;
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

      shellAliases = {
        pi = "bwrapper pi";
        # This is the only way that works with this provider extension.
        # I can't set it in the config.
        # https://github.com/patlux/pi-commandcode-provider
        pic = "bwrapper pi --model commandcode/deepseek/deepseek-v4-flash";
      };

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
                commandcode = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.commandcodeKey.path}";
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

            ".pi/agent/models.json" = {
              generator = pkgs.writers.writeJSON "pi-agent-config.json";
              value = {
                providers = {
                  llama-cpp = {
                    baseUrl = "http://localhost:11435/v1";
                    api = "openai-completions";
                    apiKey = "dummy";
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
                defaultProvider = "commandcode";
                defaultModel = "deepseek/deepseek-v4-flash";
                enabledModels = [
                  "commandcode/*deepseek-v4*"
                  "opencode-go/*deepseek-v4*"

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
                    source = "git:github.com/plumj-am/pi-commandcode-provider";
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
                      "answer.ts"
                      "btw.ts"
                      "context.ts"
                      "loop.ts"
                      "multi-edit.ts"
                      "todos.ts"
                    ];
                    themes = [ ];
                    skills = [ "librarian" ];
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
          };
        };
    };
}
