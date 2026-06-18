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
      inherit (lib.meta) getExe;
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
              model = "commandcode/deepseek-v4-pro";
              small_model = "commandcode/deepseek-v4-flash";

              plugin = [
                "oh-my-openagent"
                "oh-my-openagent/tui"
                "commandcode-go-opencode-provider"
                "context-mode"
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
                };
              };

              agent = {
                build = {
                  mode = "primary";
                  model = "commandcode/deepseek-v4-pro";
                };

                researcher = {
                  mode = "primary";
                  model = "commandcode/deepseek-v4-flash";
                  description = "Read-only research primarily using the web";
                };

                explore = {
                  mode = "subagent";
                  model = "commandcode/deepseek-v4-flash";
                };
              };

              provider.commandcode = {
                timeout = 3000000;
                chunkTimeout = 1500000;
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

                nixos = {
                  type = "local";
                  command = [
                    "${getExe pkgs.nix}"
                    "run"
                    "github:utensils/mcp-nixos"
                    "--"
                  ];
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
        };
      };
    };
}
