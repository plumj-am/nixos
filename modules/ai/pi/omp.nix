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
            source = ../AGENTS.md;
          };

          ".omp/agent/config.yml" = {
            type = "copy"; # Sometimes needs to write to config.
            generator = pkgs.writers.writeYAML "omp-agent-config.yml";
            value = {
              defaultProvider = "commandcode";
              defaultModel = "deepseek-v4-flash";

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
                # "opencode-go"
                "opencode-zen"
              ];
              modelRoles =
                let
                  # TODO: switch to commandcode once provider is supported
                  small = "opencode-zen/deepseek-v4-flash-free";
                  normal = "opencode-zen/big-pickle"; # maybe kimi-k2.6 better here
                  vision = "commandcode/kimi-k2.5"; # idk if it supports vision lol
                in
                {
                  default = "${normal}:auto";
                  smol = "${small}:off";
                  slow = "${normal}:high";
                  plan = "${normal}:high";
                  vision = "${vision}:low";
                  designer = "${normal}:low";
                  commit = "${small}:off";
                  task = "${small}:minimal";
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
                ponytail = "https://github.com/DietrichGebert/ponytail";
                omp-cmd = "https://github.com/bl4zee1g/omp-cmd";
              };
            };
          };
        };
      };
    };
}
