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
      inherit (config.sops) secrets;

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
    in
    {
      ai.secrets = true;

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
              model = "commandcode/deepseek-v4-flash";
              small_model = "commandcode/deepseek-v4-flash";

              experimental = {
                disable_paste_summary = true;
              };

              plugin = [
                "commandcode-go-opencode-provider"
                "@tarquinen/opencode-dcp"
                "@plannotator/opencode"
                "opencode-tps-meter"
                "@dietrichgebert/ponytail"
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

              agent = {
                build = {
                  mode = "primary";
                  model = "commandcode/deepseek/deepseek-v4-flash";
                  reasoningEffort = "high";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                plan = {
                  mode = "primary";
                  model = "commandcode/deepseek/deepseek-v4-flash";
                  reasoningEffort = "max";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                general = {
                  mode = "subagent";
                  model = "commandcode/deepseek/deepseek-v4-flash";
                  reasoningEffort = "high";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };

                explore = {
                  mode = "subagent";
                  model = "commandcode/deepseek/deepseek-v4-flash";
                  reasoningEffort = "low";
                  textVerbosity = "low";
                  thinking.type = "disabled";
                };

                scout = {
                  mode = "subagent";
                  model = "commandcode/deepseek/deepseek-v4-flash";
                  reasoningEffort = "high";
                  textVerbosity = "low";
                  thinking.type = "enabled";
                };
              };

              provider.commandcode = {
                timeout = 3000000;
                chunkTimeout = 1500000;

                models =
                  genAttrs [
                    "deepseek/deepseek-v4-pro"
                    "deepseek/deepseek-v4-flash"
                  ]
                  <| const {
                    variants = {
                      # "In thinking mode, for compatibility, low and medium are mapped to high, and xhigh is mapped to max"
                      # <https://api-docs.deepseek.com/guides/thinking_mode>
                      Max = {
                        reasoningEffort = "max";
                        textVerbosity = "low";
                        thinking.type = "enabled";
                      };
                      Default = {
                        reasoningEffort = "high";
                        textVerbosity = "low";
                        thinking.type = "enabled";
                      };
                    };
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
                    "cargo"
                    "fmt"
                    "--"
                    "$FILE"
                  ];
                  extensions = [ ".rs" ];
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
                    CONTEXT7_API_KEY = "{file:${secrets."context7-key".path}}";
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
