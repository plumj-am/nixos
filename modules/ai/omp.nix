{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.omp;
  flake.modules.common.omp =
    {
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

      system = pkgs.stdenv.hostPlatform.system;

      # Guardrails for mistakes that recur in previous sessions. Conditions match the
      # agent's own output, so they gate the action before it runs.
      ttsrRules = {
        no-system-switch = ''
          ---
          description: Do not switch the running system
          condition: '(?:nh\s+os\s+(?:switch|boot)|nixos-rebuild\s+(?:switch|boot|test)|nix\s+run\s+\.#rebuild)'
          scope: 'tool:bash'
          ---

          Do not activate or switch the system. Build and smoke-test only; the user
          runs `nh os switch` or `nixos-rebuild switch` themselves and reports back.
          If a switch is required to finish the task, say so and stop.
        '';

        no-secret-decrypt = ''
          ---
          description: Do not decrypt sops secrets
          condition: '(?:sops\s+(?:-d|--decrypt)|sops\s+-e)'
          scope: 'tool:bash'
          ---

          Never decrypt secrets. There is no permission to read the plaintext and it
          must not enter the session log. Work from module option names; ask the user
          for the value only if it is truly required.
        '';

        flake-check-tail = ''
          ---
          description: Keep the nix flake check exit status
          condition: 'nix\s+flake\s+check[^\n|]*\|\s*(?:tail|head)'
          scope: 'tool:bash'
          ---

          Do not pipe `nix flake check` into tail or head. That hides the exit status
          and the failing check name, and the whole cached check re-runs. Let it
          print, or capture the log and read the file.
        '';

        no-sleep-poll = ''
          ---
          description: Do not sleep-poll a background job
          condition: 'sleep\s+\d+\s*(?:&&|;)\s*(?:ps|pgrep|pidwait|stat|ls|tail|cat|grep)'
          scope: 'tool:bash'
          ---

          Do not poll. The job was backgrounded because it outlived the call, and its
          result is delivered automatically. Do other work, or end the turn and read
          the job with `proc://bg_N` later.
        '';

        no-python-rewrite = ''
          ---
          description: Do not rewrite files with python one-liners
          condition:
            - '\.write_text\('
            - 'open\([^)\n]{0,80}["\x27]w["\x27]\)'
          scope: 'tool:bash'
          ---

          Do not modify files through python. Use the `edit` tool for existing files
          and `write` for new ones: they give a diff preview and fuzzy matching, and
          they keep the hashline state consistent.
        '';

        builders-empty = ''
          ---
          description: Do not disable builders with an empty value
          condition: '--builders\s+(?:[\x27\x22]{2}|$)'
          scope: 'tool:bash'
          ---

          An empty builders list is not the local-only switch the user wants. Use the
          exact flag they named and confirm it did what they expected, rather than
          substituting another flag that looks equivalent.
        '';

        nix-pure-parse = ''
          ---
          description: Parse-check Nix files impurely
          condition: 'nix-instantiate\s+--parse(?![^\n]*--impure)'
          scope: 'tool:bash'
          ---

          `nix-instantiate --parse` on a repo path fails in pure evaluation mode. Pass
          `--impure`, or feed the file on stdin, and never pipe the output through
          tail: that hides the exit status you are checking.
        '';

        nix-double-prefix = ''
          ---
          description: Fix a doubled system prefix in a Nix installable
          condition: '#packages\.x86_64-linux\.packages\.'
          scope: 'tool:bash'
          ---

          The installable repeats the system prefix. Use
          `.#packages.x86_64-linux.<name>` once, or `.#<name>` when the host's package
          set is already the default.
        '';

        premature-done = ''
          ---
          description: Ground a completion claim in real output
          condition:
            - '(?i)all (?:checks|tests) (?:pass|green)'
            - '(?i)fully verified'
            - '(?i)verification (?:is )?complete'
            - '(?i)everything (?:passes|is green)'
          scope: 'text'
          interruptMode: prose-only
          ---

          You are claiming completion. Name the exact command and the pin it ran
          against, and paste the output you saw. If it was a channel nixpkgs, a cached
          result, a subset of checks, or a build with no smoke run, say that instead.
        '';
      };
    in
    {
      ai.secrets = true;

      environment.systemPackages = [
        self.packages.${system}.omp-wrapped
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

              prewalk.enabled = true; # start big, implement with small.

              enabledModels = [ ]; # all
              modelProviderOrder = singleton providerKey;
              modelRoles = with models; {
                inherit tiny vision;
                default = "${small}:high";
                smol = small;
                slow = "${big}:max";
                advisor = small;
                plan = "${big}:max";
                designer = vision;
                commit = small;
                task = tiny;
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
              compaction.thresholdTokens = 400000; # context maintenance starts at 400k tokens for applicable models

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
              mnemopi.noEmbeddings = true;
              mnemopi.llmMode = "none";
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
              skills.enableAgentsProject = true;

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
              };
            };
          };

          ".omp/agent/extensions/theme.ts".source =
            self.packages.${pkgs.stdenv.hostPlatform.system}.omp-theme;

          ".omp/agent/extensions/grove-goal.ts".source =
            self.packages.${pkgs.stdenv.hostPlatform.system}.omp-grove-goal;
        }
        // mapAttrs' (name: text: nameValuePair ".omp/agent/rules/${name}.md" { inherit text; }) ttsrRules;
      };
    };
}
