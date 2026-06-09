{
  flake.modules.common.omp =
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
        exaKey = {
          rekeyFile = ../../../secrets/exa-key.age;
          owner = "jam";
          group = "users";
          mode = "600";
        };
      };

      shellAliases.omp = "bwrapper omp";

      hjem.extraModule = {
        packages = singleton inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp;

        # Another that doesn't follow XDG spec, amazing...
        files = {
          ".omp/agent/AGENTS.md" = {
            type = "copy";
            source = ../AGENTS.md;
          };

          ".omp/agent/config.yml" = {
            type = "copy"; # Sometimes needs to write to config.
            generator = pkgs.writers.writeYAML "omp-agent-config.yml";
            value = {
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

              # [internal]
              memories.enabled = false;
              modelProviderOrder = [
                "commandcode"
                "opencode-go"
              ];
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
              shellPath = getExe pkgs.bash;

              # [memory]
              memory.backend = "off";

              # [model]
              defaultThinkingLevel = "medium";
              hideThinkingBlock = true;
              retry = {
                maxRetries = 10;
                maxDelayMs = 600000;
              };

              # [providers]
              secrets.enabled = true;
              providers = {
                webSearch = "auto";
                image = "auto";
                tinyModel = "deepseek-v4-flash";
              };
              exa = {
                enabled = true;
                enableSearch = true;
                enableResearcher = false;
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
              };
              find.enabled = true;
              search.enabled = true;
              astGrep.enabled = true;
              irc.enabled = true;
              renderMermaid.enable = true;
              debug.enabled = true;
              checkpoint.enabled = true;
              fetch.enabled = true;
              github.enabled = true;
              web_search.enabled = true;
              browser.enabled = true;
              async.enabled = true;
              mcp.discoveryMode = true;

              # defaultProvider = "commandcode";
              # defaultModel = "deepseek-v4-flash";
            };
          };

          # ".omp/plugins/package.json" = {
          #   type = "copy";
          #   generator = pkgs.writers.writeJSON "omp-plugins-package.json";
          #   value = {
          #     name = "omp-plugins";
          #     private = true;
          #     dependencies = {
          #       pi-commandcode-provider = "0.4.0";
          #     };
          #   };
          # };

          # Yes, I could just `".pi/agent/extensions".source = ./extensions`
          # but this way I can add and remove easily.
          # ".pi/agent/extensions/system-theme.ts".source = ./extensions/system-theme.ts;
          # ".pi/agent/extensions/permissions.ts".source = ./extensions/permissions.ts;
          # ".pi/agent/extensions/plan-mode.ts".source = ./extensions/plan-mode.ts;
          # ".pi/agent/extensions/read-only-mode.ts".source = ./extensions/read-only-mode.ts;
          # ".pi/agent/extensions/zellij-attention.ts".source = ./extensions/zellij-attention.ts;
          # ".pi/agent/extensions/caveman.ts".source = ./extensions/caveman.ts;
          # ".pi/agent/extensions/tps-status.ts".source = ./extensions/tps-status.ts;

          # ".pi/agent/skills/caveman".source = ./skills/caveman;
          # ".pi/agent/skills/gh-grep".source = ./skills/gh-grep; # Taken from <https://github.com/huynguyen03dev/opencode-setup/tree/main/skills/gh-grep>
        };
      };
    };
}
