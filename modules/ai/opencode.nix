{
  flake.modules.common.opencode =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.attrsets) genAttrs;
      inherit (lib.trivial) const;

      opencodePackage = pkgs.symlinkJoin {
        name = "opencode-wrapped";
        paths = singleton pkgs.opencode;
        buildInputs = singleton pkgs.makeWrapper;
        postBuild = # sh
          ''
            wrapProgram $out/bin/opencode \
              --set OPENCODE_EXPERIMENTAL true \
              --set OPENCODE_ENABLE_EXA 1
          '';
      };

      big = "commandcode/deepseek-v4-pro";
      small = "commandcode/deepseek-v4-flash";
      cheap = "opencode/deepseek-v4-flash-free";

      bigFallback = [
        "commandcode/minimax-m3"
      ];
      smallFallback = [
        "opencode/deepseek-v4-flash-free"
      ];
      cheapFallback = [
        "commandcode/step-3.5-flash"
        "commandcode/deepseek-v4-flash"
      ];
    in
    {
      ai.secrets = true;

      shellAliases.opencode = "bwrapper opencode";

      hjem.extraModule = {
        packages = [
          pkgs.python3
          pkgs.uv
          opencodePackage
        ];

        xdg.config.files = {
          "opencode/AGENTS.md" = {
            type = "copy";
            source = ./AGENTS.md;
          };

          "opencode/opencode.json" = {
            generator = pkgs.writers.writeJSON "opencode-opencode.jsonc";
            value = {
              autoupdate = false;
              model = small;
              small_model = cheap;

              experimental = {
                disable_paste_summary = true;
              };

              plugin = [
                "@tarquinen/opencode-dcp"
                "@plannotator/opencode"
                "opencode-tps-meter"
                "@dietrichgebert/ponytail"
                "opencode-runtime-fallback"
                [
                  "@prevalentware/opencode-goal-plugin"
                  {
                    auto_continue = true;
                    defer_while_tasks_active = true;
                    max_auto_turns = 25;
                    min_continue_interval_seconds = 3;
                    max_prompt_failures = 10;
                    no_progress_token_threshold = 50;
                    max_no_progress_turns = 2;
                    restricted_agents = [ "plan" ];
                    allow_goal_execution_from_plan = false;
                  }
                ]
              ];

              permission = {
                "*" = "ask";
                edit = "allow";
                codesearch = "allow";
                glob = "allow";
                grep = "allow";
                list = "allow";
                lsp = "allow";
                question = "allow";
                read = "allow";
                task = "allow";
                todoread = "allow";
                todowrite = "allow";
                websearch = "allow";

                "context7_*" = "allow";
                "gh_grep_*" = "allow";
                "grep_app_*" = "allow";
                "websearch_*" = "allow";
                "web-reader_*" = "allow";
                "web-search-prime_*" = "allow";
                "nixos_*" = "allow";
                "lsp_*" = "allow";
                "zread_*" = "allow";

                bash = genAttrs config.ai.commands.bash.allow (const "allow");

                external_directory = {
                  "/tmp/**" = "allow";
                  "~/.cargo/registry/src/**" = "allow";
                  "~/.local/share/opencode/**" = "allow";
                };
              };

              provider.commandcode = {
                npm = "@ai-sdk/openai-compatible";
                name = "Command Code";

                options = {
                  baseURL = "https://api.commandcode.ai/provider/v1";
                  apiKey = "{env:COMMANDCODE_API_KEY}";
                };

                timeout = 3000000;
                chunkTimeout = 1500000;

                models = {
                  deepseek-v4-flash = {
                    id = "deepseek/deepseek-v4-flash";
                    name = "DeepSeek V4 Flash";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 1000000;
                      output = 384000;
                    };
                  };
                  deepseek-v4-pro = {
                    id = "deepseek/deepseek-v4-pro";
                    name = "DeepSeek V4 Pro";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 1000000;
                      output = 384000;
                    };
                  };
                  "step-3.5-flash" = {
                    id = "stepfun/Step-3.5-Flash";
                    name = "Step 3.5 Flash";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 1000000;
                      output = 384000;
                    };
                  };
                  minimax-m3 = {
                    id = "MiniMaxAI/MiniMax-M3";
                    name = "MiniMax M3";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 1000000;
                      output = 131072;
                    };
                  };
                };
              };

              agent = {
                build = {
                  mode = "primary";
                  model = small;
                  fallback_models = smallFallback;
                  reasoningEffort = "medium";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                plan = {
                  mode = "primary";
                  model = big;
                  fallback_models = bigFallback;
                  reasoningEffort = "max";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                general = {
                  mode = "subagent";
                  model = small;
                  fallback_models = smallFallback;
                  reasoningEffort = "high";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                explore = {
                  mode = "subagent";
                  model = cheap;
                  fallback_models = cheapFallback;
                  reasoningEffort = "low";
                  textVerbosity = "low";
                  thinking.type = "disabled";
                };

                scout = {
                  mode = "subagent";
                  model = cheap;
                  fallback_models = cheapFallback;
                  reasoningEffort = "low";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };
              };

              lsp = {
                nixd = {
                  command = [ "nixd" ];
                  extensions = [ ".nix" ];
                };

                qmlls = {
                  command = [ "qmlls" ];
                  extensions = [ ".qml" ];
                };
              };

              formatter = {
                rustfmt = {
                  command = [
                    "rustfmt"
                    "--"
                    "$FILE"
                  ];
                  extensions = [ ".rs" ];
                };
                nixfmt = {
                  command = [
                    "nixfmt"
                    "$FILE"
                  ];
                  extensions = [ ".nix" ];
                };
                qmlformat = {
                  command = [
                    "qmlformat"
                    "--inplace"
                    "$FILE"
                  ];
                  extensions = [ ".qml" ];
                };
              };

              mcp = {
                context7 = {
                  type = "remote";
                  url = "https://mcp.context7.com/mcp";
                  headers = {
                    CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
                  };
                };

                gh_grep = {
                  type = "remote";
                  url = "https://mcp.grep.app";
                };
              };
            };
          };

          "opencode/tui.json" = {
            generator = pkgs.writers.writeJSON "opencode-tui.jsonc";
            value = {
              theme = "gruvbox";

              plugin = [
                "opencode-tps-meter"
              ];

              keybinds = {
                app_exit = "ctrl+c";
                messages_half_page_up = "ctrl+u";
                messages_half_page_down = "ctrl+d";
                input_newline = "shift+enter";
              };
            };
          };

          "opencode/dcp.json" = {
            generator = pkgs.writers.writeJSON "opencode-tui.jsonc";
            value = {
              enabled = true;
              autoUpdate = false;
              experimental.allowSubAgents = true;
            };
          };
        };
      };
    };
}
