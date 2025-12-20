{ pkgs, lib, config, inputs, ... }: let
  inherit (lib) enabled mkIf;
in {
  unfree.allowedNames = mkIf config.isDesktop [ "claude-code" "codex" ];

  environment.shellAliases = mkIf config.isDesktop {
    claude = "claude --continue --fork-session";
    codex  = "codex resume --ask-for-approval untrusted";
    oc     = "opencode --continue";
  };

  environment.systemPackages = mkIf config.isDesktop [
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
    programs.claude-code = mkIf config.isDesktop (enabled {
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

      	statusLine = {
      		type    = "command";
      		command = "python3 ~/.claude/scripts/statusline.py";
      	};

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
              matcher = "permission_prompt|elicitation_dialog";
              hooks   = [
                {
                  type    = "command";
                  command = "${pkgs.libnotify}/bin/notify-send --expire-time=15000 'Claude' 'Waiting for approval.'";
                }
              ];
            }
            {
              matcher = "idle_prompt";
              hooks   = [
                {
                  type    = "command";
                  command = "${pkgs.libnotify}/bin/notify-send --expire-time=15000 'Claude' 'Waiting for next message.'";
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

          "Bash(fj issue search:*)"
          "Bash(fj issue view:*)"
          "Bash(fj actions tasks:*)"
          "Bash(fj wiki contents:*)"
          "Bash(fj wiki view:*)"

          "mcp__context7"
          "mcp__gh_grep"
          "mcp__web-reader"
          "mcp__web-search-prime"
          "mcp__nixos"
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
    });

    programs.opencode = enabled {
      # We don't need latest for CI runners.
      package = mkIf config.isDesktop inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;

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

    # Statusline script.
    home.file.".claude/scripts/statusline.py" = {
      text = /* py */ ''
          #!/usr/bin/env python3
          """
          PlumJam's Claude Code Statusline
          <https://git.plumj.am/plumjam/nixos/src/branch/master/modules/common/ai.nix>
          """

          import json
          import sys
          import os
          import re
          import time

          def parse_context_from_transcript(transcript_path):
              if not transcript_path or not os.path.exists(transcript_path):
                  return None

              try:
                  with open(transcript_path, 'r', encoding='utf-8', errors='replace') as f:
                      lines = f.readlines()

                  # Check last 15 lines for context information.
                  recent_lines = lines[-15:] if len(lines) > 15 else lines

                  for line in reversed(recent_lines):
                      try:
                          data = json.loads(line.strip())

                          # Method 1: Parse usage tokens from assistant messages.
                          if data.get('type') == 'assistant':
                              message = data.get('message', {})
                              usage = message.get('usage', {})

                              if usage:
                                  input_tokens = usage.get('input_tokens', 0)
                                  cache_read = usage.get('cache_read_input_tokens', 0)
                                  cache_creation = usage.get('cache_creation_input_tokens', 0)

                                  # Estimate context usage (assume 200k).
                                  total_tokens = input_tokens + cache_read + cache_creation
                                  if total_tokens > 0:
                                      percent_used = min(100, (total_tokens / 200000) * 100)
                                      return {
                                          'percent': percent_used,
                                          'tokens': total_tokens,
                                          'method': 'usage'
                                      }

                          # Method 2: Parse system context warnings.
                          elif data.get('type') == 'system_message':
                              content = data.get('content', "")

                              # "Context left until auto-compact: X%"
                              match = re.search(r'Context left until auto-compact: (\d+)%', content)
                              if match:
                                  percent_left = int(match.group(1))
                                  return {
                                      'percent': 100 - percent_left,
                                      'warning': 'auto-compact',
                                      'method': 'system'
                                  }

                              # "Context low (X% remaining)"
                              match = re.search(r'Context low \((\d+)% remaining\)', content)
                              if match:
                                  percent_left = int(match.group(1))
                                  return {
                                      'percent': 100 - percent_left,
                                      'warning': 'low',
                                      'method': 'system'
                                  }

                      except (json.JSONDecodeError, KeyError, ValueError):
                          continue

                  return None

              except (FileNotFoundError, PermissionError):
                  return None

          def get_context_display(context_info):
              if not context_info:
                  return f"\033[38;5;109m━┫          ┣━ 0%\033[0m"

              percent = context_info.get('percent', 0)
              warning = context_info.get('warning')

              # Create progress bar.
              segments = 10
              filled = int((percent / 100) * segments)
              bar = "█" * filled + " " * (segments - filled)

              return f"\033[38;5;109m━┫ [{bar}] ┣━{percent:.0f}%\033[0m"

          def get_directory_display(workspace_data):
              current_dir = workspace_data.get('current_dir', "")
              project_dir = workspace_data.get('project_dir', "")

              if current_dir and project_dir:
                  if current_dir.startswith(project_dir):
                      rel_path = current_dir[len(project_dir):].lstrip('/')
                      return rel_path or os.path.basename(project_dir)
                  else:
                      return os.path.basename(current_dir)
              elif project_dir:
                  return os.path.basename(project_dir)
              elif current_dir:
                  return os.path.basename(current_dir)
              else:
                  return "unknown"

          def get_session_duration(duration_ms):
              if duration_ms > 0:
                  minutes = duration_ms / 60000
                  if minutes < 1:
                      return f"{duration_ms//1000}s"
                  else:
                      return f"{minutes:.0f}m"

              return ""

          def main():
              try:
                  # Read JSON input from claude-code.
                  data = json.load(sys.stdin)

                  model_name = data.get('model', {}).get('display_name', 'Claude')
                  workspace = data.get('workspace', {})
                  transcript_path = data.get('transcript_path', "")
                  cost_data = data.get('cost', {})

                  thinking_enabled = os.environ.get('THINKING_ENABLED', "").lower() in ('true', '1', 'yes')

                  context_info = parse_context_from_transcript(transcript_path)

                  context_display = get_context_display(context_info)
                  directory = get_directory_display(workspace)

                  duration_ms = cost_data.get('total_duration_ms', 0)
                  session_duration = get_session_duration(duration_ms)

                  thinking_indicator = " \033[38;5;172m|\033[0m \033[38;5;142mTHINKING\033[0m " if thinking_enabled else " "

                  # Combine all components in the correct format.
                  status_line = f"\033[38;5;142m[{model_name}]\033[0m \033[38;5;214m{directory}\033[0m{thinking_indicator}{context_display}"

                  if session_duration:
                      status_line += f" \033[38;5;172m|\033[0m \033[38;5;214m{session_duration}\033[0m"

                  print(status_line)

              except Exception as e:
                  # Fallback display on any error.
                  print("error")

          if __name__ == "__main__":
              main()

        '';

    };

    # Helper script to add MCPs.
    home.file.".claude/claude-mcps.sh" = {
      text = /* bash */ ''
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
