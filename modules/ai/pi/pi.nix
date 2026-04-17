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
              value = {
                opencode-go = {
                  type = "api_key";
                  key = "!cat ${osConfig.age.secrets.opencodeGoKey.path}";
                };
              };
            };

            ".pi/agent/mcp.json" = {
              generator = pkgs.writers.writeJSON "pi-agent-mcp.json";
              value = {
                mcpServers = {
                  context7 = {
                    url = "https://mcp.context7.com/mcp/oauth";
                    directTools = true;
                  };

                  gh_grep = {
                    url = "https://mcp.grep.app";
                    directTools = true;
                  };

                  nixos = {
                    command = "${getExe pkgs.nix}";
                    args = [
                      "run"
                      "github:utensils/mcp-nixos"
                      "--"
                    ];
                    directTools = true;
                  };
                };
              };
            };

            ".pi/agent/settings.json" = {
              type = "copy"; # Sometimes needs to write to config.
              generator = pkgs.writers.writeJSON "pi-agent-config.json";
              value = {
                defaultProvider = "opencode-go";
                defaultModel = "minimax-m2.7";
                enabledModels = [
                  "minimax-*"
                  "kimi-*"
                  "qwen3*"
                ];

                enableInstallTelemetry = false;
                editorPaddingX = 1;

                shellPath = getExe pkgs.bash;

                packages = [
                  "git:github.com/nicobailon/pi-subagents"
                  "git:github.com/nicobailon/pi-interview-tool"
                  "git:github.com/nicobailon/pi-web-access"
                  "git:github.com/nicobailon/pi-mcp-adapter"
                  {
                    source = "git:github.com/mitsuhiko/agent-stuff";
                    extensions = [
                      "!apple-mail"
                      "!control"
                      "!go-to-bed"
                      "!split-fork"
                      "!uv"
                      "!whimsical"
                    ];
                    themes = [ ];
                    skills = [ ];
                  }
                  {
                    source = "git:github.com/hjanuschka/shitty-extensions";
                    extensions = [ ];
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

            # Seeing how well the extension alone works.
            # ".pi/agent/skills/caveman/SKILL.md".source = ./skills/caveman.md;

            ".pi/agent/agents".source = ./agents;
          };
        };
    };
}
