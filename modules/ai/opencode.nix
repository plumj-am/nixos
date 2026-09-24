{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.opencode;
  flake.modules.common.opencode =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets)
        filterAttrs
        genAttrs
        listToAttrs
        mapAttrs
        mapAttrs'
        nameValuePair
        optionalAttrs
        ;
      inherit (lib.lists) singleton takeEnd;
      inherit (lib.strings) concatStringsSep splitString;
      inherit (lib.trivial) const;
      inherit (config.ai) defaultModels;
      inherit (config.sops) secrets;

      providerKey = config.ai.providers.headroomVineProxy.name;

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

      shortId =
        id:
        id
        |> splitString "/"
        |> takeEnd 2
        |> concatStringsSep "/";

      modelRefs = mapAttrs (_: id: "${providerKey}/${shortId id}") defaultModels;

      mkAgent =
        {
          mode ? "subagent",
          model ? modelRefs.small,
          effort ? "low",
          thinking ? true,
        }:
        {
          inherit mode model;
          reasoningEffort = effort;
          textVerbosity = "low";
          thinking.type = if thinking then "enabled" else "disabled";
        };
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
              model = modelRefs.big;
              small_model = modelRefs.small;

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

              provider =
                config.ai.providers
                |> filterAttrs (_: provider: !(provider ? discoveryType))
                |> mapAttrs' (
                  _: provider:
                  nameValuePair provider.name (
                    {
                      models =
                        config.ai.models
                        |> map (
                          model:
                          nameValuePair (shortId model.id) {
                            inherit (model) id name reasoning;
                            tool_call = true;
                            limit = {
                              inherit (model) context;
                              output = model.maxOutput;
                            };
                          }
                        )
                        |> listToAttrs;

                      inherit (provider) name;

                      options = {
                        baseURL = provider.baseUrl;
                      }
                      // optionalAttrs (provider ? apiKey) { inherit (provider) apiKey; };

                      timeout = 60 * 60 * 1000; # 60 min
                      chunkTimeout = 30 * 60 * 1000; # 30 min
                    }
                    // optionalAttrs (provider.type == "openai-compatible") { npm = "@ai-sdk/openai-compatible"; }
                  )
                );

              agent = {
                build = mkAgent {
                  mode = "primary";
                  effort = "medium";
                };
                plan = mkAgent {
                  mode = "primary";
                  model = modelRefs.big;
                  effort = "max";
                };
                general = mkAgent {
                  effort = "high";
                };
                explore = mkAgent { };
                scout = mkAgent { };
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
