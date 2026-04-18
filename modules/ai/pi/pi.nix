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
      age.secrets.opencodeGoKey = {
        rekeyFile = ../../../secrets/opencode-go-key.age;
        owner = "jam";
        group = "users";
        mode = "600";
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
              };
            };

            ".pi/agent/models.json" = {
              generator = pkgs.writers.writeJSON "pi-agent-config.json";
              value = {
                providers.litellm = {
                  baseUrl = "http://localhost:4000";
                  api = "openai-completions";
                  apiKey = "dummy";
                  models = [
                    {
                      id = "minimax-m2.7";
                      reasoning = true;
                      contextWindow = 204800;
                    }
                    {
                      id = "minimax-m2.5";
                      reasoning = true;
                      contextWindow = 204800;
                    }
                    {
                      id = "glm-5.1";
                      reasoning = true;
                      contextWindow = 204800;
                    }
                    {
                      id = "glm-5";
                      reasoning = true;
                      contextWindow = 204800;
                    }
                    {
                      id = "kimi-k2.5";
                      reasoning = true;
                      contextWindow = 262144;
                    }
                    {
                      id = "kimi-k2.6";
                      reasoning = true;
                      contextWindow = 262144;
                    }
                    {
                      id = "mimo-v2-pro";
                      reasoning = true;
                      contextWindow = 1048576;
                    }
                    {
                      id = "mimo-v2-omni";
                      reasoning = true;
                      contextWindow = 262144;
                    }
                    {
                      id = "qwen3.6-plus";
                      reasoning = true;
                      contextWindow = 1048576;
                    }
                    {
                      id = "qwen3.5-plus";
                      reasoning = true;
                      contextWindow = 262144;
                    }
                  ];
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
                defaultProvider = "litellm";
                defaultModel = "kimi-k2.6";
                enabledModels = [
                  "minimax-*"
                  "kimi-*"
                  "qwen3*"
                ];

                quietStartup = true;
                hideThinkingBlock = true;

                enableInstallTelemetry = false;
                editorPaddingX = 1;

                shellPath = getExe pkgs.bash;

                packages = [
                  "git:github.com/nicobailon/pi-interview-tool"
                  "git:github.com/apmantza/GreedySearch-pi"
                  {
                    source = "git:github.com/netresearch/context7-skill";
                    extensions = [ ];
                    themes = [ ];
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

            ".pi/agent/skills/caveman".source = ./skills/caveman;
            ".pi/agent/skills/gh-grep".source = ./skills/gh-grep; # Taken from <https://github.com/huynguyen03dev/opencode-setup/tree/main/skills/gh-grep>

            ".pi/agent/agents".source = ./agents;
          };
        };
    };
}
