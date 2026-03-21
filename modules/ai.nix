let
  aiBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe getExe';
      inherit (config.age) secrets;

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
      hjem.extraModules = singleton {
        packages = [
          pkgs.python3
          pkgs.uv
          opencodePackage
        ];

        xdg.config.files."opencode/opencode.jsonc" = {
          generator = pkgs.writers.writeJSON "opencode-opencode.jsonc";
          value = {
            theme = "gruvbox";
            autoupdate = false;
            model = "zai-coding-plan/glm-5";
            small_model = "zai-coding-plan/glm-4.7-flash";

            permission = {
              list = "allow";
              lsp = "allow";
              glob = "allow";
              grep = "allow";
              question = "allow";
              read = "allow";
              webfetch = "ask";
              websearch = "allow";

              "context7_*" = "allow";
              "gh_grep_*" = "allow";
              "web-reader_*" = "allow";
              "web-search-prime_*" = "allow";
              "nixos_*" = "allow";
            };

            agent = {
              build = {
                mode = "primary";
                model = "zai-coding-plan/glm-5";

                permission = {
                  write."*" = "allow";
                  bash."*" = "allow";
                  read."*" = "allow";

                  bash."curl*" = "ask";
                  bash."git stash*" = "ask";

                  read."*.env" = "deny";
                  read."*.envrc" = "deny";
                  bash."git reset*" = "deny";
                  bash."git checkout*" = "deny";
                  bash."git restore*" = "deny";
                  bash."git switch*" = "deny";
                  bash."git push*" = "deny";
                  bash."git commit*" = "deny";
                  bash."jj*" = "deny";
                };
              };

              researcher = {
                mode = "primary";
                model = "zai-coding-plan/glm-5";
                description = "Read-only research primarily using the web";

                tools = {
                  read = true;
                  bash = false;
                  write = false;
                  edit = false;
                  list = true;
                  glob = true;
                  grep = true;
                  webfetch = false;
                  task = true;
                  todowrite = true;
                  todoread = true;
                };
              };

              explore = {
                model = "zai-coding-plan/glm-4.7-flash";
              };
            };

            keybinds = {
              app_exit = "ctrl+c";
              messages_half_page_up = "ctrl+u";
              messages_half_page_down = "ctrl+d";
              input_newline = "shift+enter";
            };

            lsp = {
              nixd = {
                command = [ "nixd" ];
                extensions = [ ".nix" ];
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
            };

            provider.zai-coding-plan = {
              options.timeout = 600000;
              models =
                let
                  inherit (lib.attrsets) genAttrs;
                  inherit (lib) elem;

                  models = [
                    "glm-5"
                    "glm-4.7"
                    "glm-4.7-flashx"
                    "glm-4.7-flash"
                    "glm-4.6"
                    "glm-4.5"
                    "glm-4.5-x"
                    "glm-4.5-air"
                    "glm-4.5-airx"
                    "glm-4.5-flash"
                  ];

                  supportsToolStreaming = [ "glm-5" ];
                in
                genAttrs models (name: {
                  options = {
                    tool_stream = elem name supportsToolStreaming;
                    stream = true;
                    thinking.type = "enabled";
                  };
                });
            };

            mcp = {
              context7 = {
                type = "remote";
                url = "https://mcp.context7.com/mcp";
                headers = {
                  CONTEXT7_API_KEY = "{file:${secrets.context7Key.path}}";
                };
              };

              gh_grep = {
                type = "remote";
                url = "https://mcp.grep.app";
              };

              web-reader = {
                type = "remote";
                url = "https://api.z.ai/api/mcp/web_reader/mcp";
                headers = {
                  Authorization = "Bearer {file:${secrets.zaiKey.path}}";
                };
              };

              web-search-prime = {
                type = "remote";
                url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
                headers = {
                  Authorization = "Bearer {file:${secrets.zaiKey.path}}";
                };
              };

              zread = {
                type = "remote";
                url = "https://api.z.ai/api/mcp/zread/mcp";
                headers = {
                  Authorization = "Bearer {file:${secrets.zaiKey.path}}";
                };
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

              playwriter = {
                type = "local";
                command = [
                  "${getExe' pkgs.nodejs "npx"}"
                  "playwriter@latest"
                ];
              };
            };
          };
        };
      };
    };

  aiExtra =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;

      opencodeDesktopPackage = pkgs.symlinkJoin {
        name = "opencode-wrapped";
        paths = singleton pkgs.opencode-desktop;
        buildInputs = singleton pkgs.makeWrapper;
        postBuild = # sh
          ''
            wrapProgram $out/bin/OpenCode \
              --prefix GST_PLUGIN_PATH : "${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0" \
              --set OPENCODE_EXPERIMENTAL true \
              --set OPENCODE_ENABLE_EXA 1
          '';
      };
    in
    {
      hjem.extraModules = singleton {
        packages = [
          pkgs.codex
          pkgs.gemini-cli
          opencodeDesktopPackage
          pkgs.qwen-code
        ];
      };
    };
in
{
  flake.modules.nixos.ai = aiBase;
  flake.modules.darwin.ai = aiBase;

  flake.modules.nixos.ai-extra = aiExtra;
  flake.modules.darwin.ai-extra = aiExtra;
}
