{ pkgs, lib, config, inputs, ... }: let
  inherit (lib) enabled;
in {
  unfree.allowedNames = [ "claude-code" "codex" ];

  environment.shellAliases = {
    claude = "claude --continue --fork-session";
    codex  = "codex resume --ask-for-approval untrusted";
    oc     = "opencode --continue";
  };

  environment.systemPackages = [
    pkgs.codex
    pkgs.qwen-code
    pkgs.gemini-cli
  ];

  age.secrets.key = {
    rekeyFile = ./z-ai-key.age;
    owner = "jam";
    mode  = "0400";
  };

  age.secrets.context7Key = {
    rekeyFile = ./context7-key.age;
    owner = "jam";
    mode  = "0400";
  };

  home-manager.sharedModules = [{
    programs.claude-code = enabled {
      package = pkgs.symlinkJoin {
        name        = "claude-code-wrapped";
        paths       = [ inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild   = ''
          wrapProgram $out/bin/claude \
            --run 'export ANTHROPIC_AUTH_TOKEN=$(cat ${config.age.secrets.key.path})'
        '';
      };

      settings = {
        cleanupPeriodDays     = 1000;
        alwaysThinkingEnabled = false;
        includeCoAuthoredBy   = false;

        env = {
          ANTHROPIC_BASE_URL   = "https://api.z.ai/api/anthropic";
          API_TIMEOUT_MS       = "3000000";

          ANTHROPIC_DEFAULT_HAIKU_MODEL  = "glm-4.5-air";
          ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-4.6";
          ANTHROPIC_DEFAULT_OPUS_MODEL   = "glm-4.6";

          CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          DISABLE_NON_ESSENTIAL_MODEL_CALLS        = "1";

        };

        hooks = {
          # Unreliable right now: https://github.com/anthropics/claude-code/issues/11947
          # Stop = [{
          #   hooks = [{
          #     type    = "prompt";
          #     prompt  = ''You are evaluating whether Claude should stop working. Context: $ARGUMENTS\n\nAnalyze the conversation and determine if:\n1. All user-requested tasks are complete\n2. Any errors need to be addressed\n3. Follow-up work is needed.'';
          #     timeout = 30;
          #   }];
          # }];

          # SubagentStop = [{
          #   hooks = [{
          #     type    = "prompt";
          #     prompt = ''Evaluate if this subagent should stop. Input: $ARGUMENTS\n\nCheck if:\n- The subagent completed its assigned task\n- Any errors occurred that need fixing\n- Additional context gathering is needed.'';
          #   }];
          # }];

          Notification = [
            {
              matcher = "permission_prompt|idle_prompt|elicitation_dialog";
              hooks   = [
                {
                  type    = "command";
                  command = "${pkgs.libnotify}/bin/notify-send --expire-time=15000 'Claude' 'Waiting for user input.'";
                }
              ];
            }
          ];

          PostToolUse = [
            {
      				matcher = "Edit|MultiEdit|Write";
      				hooks   = [
      				  {
                  type    = "command";
                  command = "~/.claude/hooks/format-files";
                }
      				];
            }
          ];
        };

        allow = [
          "Edit(PROJECT.md)"
          "Edit(CURRENT.md)"
          "Edit(STATE.md)"
          "Update(PROJECT.md)"
          "Update(CURRENT.md)"
          "Update(STATE.md)"
          "Bash(curl http://localhost:*)"
          "Bash(curl -X GET http://localhost:*)"
          "Bash(find:*)"
          "Bash(rg:*)"
        ];

        deny = [
          "Read(*.env)"
          "Read(*.envrc)"
          "Bash(git push:*)"
          "Bash(git commit:*)"
        ];
      };

      # Creating with home-manager below to avoid permissions issues.
      # hooks = {};

      mcpServers = {
        gh_grep = {
          type = "http";
          url  = "https://mcp.grep.app";
        };
        # No support for reading secrets from files yet. These are added with
        # `~/.claude/claude-mcps.sh` instead.
        # context7 = {
        #   type    = "http";
        #   url     = "https://mcp.context7.com/mcp";
        #   headers = {
        #     # We need this for higher limits but for now it's fine and doesn't stop us using it.
        #     CONTEXT7_API_KEY = "{file:${config.age.secrets.context7Key.path}}";
        #   };
        # };
        #
        # web-reader = {
        #   type    = "http";
        #   url     = "https://api.z.ai/api/mcp/web_reader/mcp";
        #   headers = {
        #     Authorization = "Bearer {file:${config.age.secrets.key.path}}";
        #   };
        # };
        #
        # web-search-prime = {
        #   type    = "http";
        #   url     = "https://api.z.ai/api/mcp/web_search_prime/mcp";
        #   headers = {
        #     Authorization = "Bearer {file:${config.age.secrets.key.path}}";
        #   };
        # };

        nixos = {
          type    = "stdio";
          command = "/run/current-system/sw/bin/nix";
          args    = [ "run" "github:utensils/mcp-nixos" "--" ];
        };

        playwriter = {
          type    = "stdio";
          command = "/run/current-system/sw/bin/npx";
          args    = [ "playwriter@latest" ];
        };

        # TODO: Add nixpkgs#mcp-grafana?
      };
    };

    programs.opencode = enabled {
      package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;

      settings = {
        theme      = "gruvbox";
        autoupdate = false;
        model      = "zai-coding-plan/glm-4.6";

        keybinds = {
          app_exit                = "ctrl+c";
          messages_half_page_up   = "ctrl+u";
          messages_half_page_down = "ctrl+d";
          input_newline           = "shift+enter";
        };

        lsp = {
          nixd = {
            command    = [ "nixd" ];
            extensions = [ ".nix" ];
          };
        };

        formatter = {
          rustfmt = {
            command    = [ "cargo" "fmt" "--" "$FILE" ];
            extensions = [ ".rs" ];
          };
        };

        provider.zai-coding-plan.models = {
          "glm-4.6".options = {
            # do_sample     = false;
            stream        = true;
            thinking.type = "enabled";
            # temperature   = 0.3;
            # max_tokens    = 32768;
          };
        };

        mcp = {
          context7 = {
            type    = "remote";
            url     = "https://mcp.context7.com/mcp";
            headers = {
              CONTEXT7_API_KEY = "{file:${config.age.secrets.context7Key.path}}";
            };
          };

          gh_grep = {
            type = "remote";
            url  = "https://mcp.grep.app";
          };

          web-reader = {
            type    = "remote";
            url     = "https://api.z.ai/api/mcp/web_reader/mcp";
            headers = {
              Authorization = "Bearer {file:${config.age.secrets.key.path}}";
            };
          };

          web-search-prime = {
            type    = "remote";
            url     = "https://api.z.ai/api/mcp/web_search_prime/mcp";
            headers = {
              Authorization = "Bearer {file:${config.age.secrets.key.path}}";
            };
          };

          nixos = {
            type    = "local";
            command = [ "/run/current-system/sw/bin/nix" "run" "github:utensils/mcp-nixos" "--" ];
          };

          playwriter = {
            type    = "local";
            command = [ "/run/current-system/sw/bin/npx" "playwriter@latest" ];
          };

          # TODO: Add nixpkgs#mcp-grafana?
        };
      };
    };
  # Create hooks with home-manager to avoid permissions issues.
    home.file.".claude/hooks/format-files" = {
      text = /* nu */ ''
        #!/usr/bin/env nu
        let json_input = (^cat)
        let file_path = ""

        if (which jq | is-empty) { exit 1 }

        let $file_path = ($json_input | from json | get tool_input.file_path)
        if ($file_path | is-empty) { exit 1 }

        let extension = ($file_path | path parse | get extension)
        let command = match ($extension | str trim) {
          "rs" if (which cargo | is-not-empty) => { ["rustfmt" $file_path] }
          "toml" if (which taplo | is-not-empty) => { ["taplo" "fmt" $file_path] }
          _ => { exit 1 }
        }
        ^$command.0 ...($command | skip 1)
      '';
      executable = true;
    };

    # Helper script to add MCPs.
    home.file.".claude/claude-mcps.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Run this once to add the MCP servers that need API keys
        claude mcp add -s user -t http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: $(cat ${config.age.secrets.context7Key.path})"
        claude mcp add -s user -t http web-reader https://api.z.ai/api/mcp/web_reader/mcp --header "Authorization: Bearer $(cat ${config.age.secrets.key.path})"
        claude mcp add -s user -t http web-search-prime https://api.z.ai/api/mcp/web_search_prime/mcp --header "Authorization: Bearer $(cat ${config.age.secrets.key.path})"
      '';
      executable = true;
    };
  }];

}
