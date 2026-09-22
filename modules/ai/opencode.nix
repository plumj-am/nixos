{
  flake.modules.common.opencode =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) singleton;
      inherit (lib.trivial) const;
      inherit (config.sops) secrets;

      # Local Vine fans out across both commandcode subs.
      providerKey = "vine";

      opencodePackage = pkgs.symlinkJoin {
        name = "opencode-wrapped";
        paths = singleton inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
        buildInputs = singleton pkgs.makeWrapper;
        postBuild = # sh
          ''
            wrapProgram $out/bin/opencode2 \
              --set OPENCODE_EXPERIMENTAL true \
              --set OPENCODE_ENABLE_EXA 1
          '';
      };

      model = "${providerKey}/xiaomi/mimo-v2.6-flash";

    in
    {
      ai.secrets = true;

      hjem.extraModule = {
        packages = [
          pkgs.python3
          pkgs.uv
          opencodePackage
          pkgs.rtk # The rtk plugin (installed by the AI plugins service) calls it.
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
              inherit model;
              small_model = model;

              experimental = {
                disable_paste_summary = true;
              };

              plugin = [
                "@plannotator/opencode"
                "opencode-tps-meter"
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
                skill = "allow";
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

              provider.${providerKey} = {
                npm = "@ai-sdk/openai-compatible";
                name = providerKey;

                options = {
                  baseURL = "http://127.0.0.1:8022/v1"; # headroom -> vine -> commandcode
                  apiKey = "sk-vine-local"; # forwarded by headroom; subs live in vine env
                };

                timeout = 3000000;
                chunkTimeout = 1500000;

                models = {
                  "deepseek-v4.1-flash" = {
                    id = "deepseek/deepseek-v4.1-flash";
                    name = "DeepSeek V4.1 Flash";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 1000000;
                      output = 384000;
                    };
                  };
                  # TODO: limited input, wait until full release with full context
                  "laguna-s2.1-free" = {
                    id = "poolside/laguna-s-2.1-free";
                    name = "Poolside Laguna S 2.1";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 256000;
                      output = 131072;
                    };
                  };
                  "mimo-v2.6-flash" = {
                    id = "xiaomi/mimo-v2.6-flash";
                    name = "Mimo v2.6 Flash";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 1048576;
                      output = 131072;
                    };
                  };
                  "mimo-v2.6-pro" = {
                    id = "xiaomi/mimo-v2.6-pro";
                    name = "Mimo v2.6 Pro";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 1048576;
                      output = 131072;
                    };
                  };
                  "muse-spark-1.3-contributor" = {
                    id = "meta/muse-spark-1.3-contributor";
                    name = "Meta Muse Spark 1.3 Contributor";
                    reasoning = true;
                    tool_call = true;
                    limit = {
                      context = 1048576;
                      output = 384000;
                    };
                  };
                };
              };

              agent = {
                build = {
                  mode = "primary";
                  inherit model;
                  reasoningEffort = "medium";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                plan = {
                  mode = "primary";
                  inherit model;
                  reasoningEffort = "max";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                general = {
                  mode = "subagent";
                  inherit model;
                  reasoningEffort = "high";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                explore = {
                  mode = "subagent";
                  inherit model;
                  reasoningEffort = "low";
                  textVerbosity = "low";
                  thinking.type = "disabled";
                };

                scout = {
                  mode = "subagent";
                  inherit model;
                  reasoningEffort = "low";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };
              };

              lsp = {
                nil = {
                  command = [ "nil" ];
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
                    "organix"
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
                    CONTEXT7_API_KEY = "{file:${secrets.context7-key.path}}";
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

          "opencode/tcp-meter.json" = {
            generator = pkgs.writers.writeJSON "opencode-tui.jsonc";
            value = {
              showAverage = false;
              showElapsed = true;

              enableColorCoding = true;
              showTpsThreshold = 40;
              fastTpsThreshold = 80;
            };
          };
        };
      };
    };
}
