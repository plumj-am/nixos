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
      inherit (lib.attrsets) genAttrs;
      inherit (lib.meta) getExe;
      inherit (lib.trivial) const;
      inherit (config.age) secrets;

      commands.allow = [
        "ag*"
        "bat*"
        "cat*"
        "fd*"
        "find*"
        "fzf*"
        "grep*"
        "head*"
        "less*"
        "ls*"
        "rg*"
        "sg*"
        "tail*"
        "tree*"

        "jj bookmark list*"
        "jj diff*"
        "jj evolog*"
        "jj file list*"
        "jj file search*"
        "jj file show*"
        "jj git colocation status*"
        "jj git remote list*"
        "jj git root*"
        "jj help*"
        "jj interdiff*"
        "jj log*"
        "jj op diff*"
        "jj op log*"
        "jj op show*"
        "jj operation diff*"
        "jj operation log*"
        "jj operation show*"
        "jj resolve --list"
        "jj root*"
        "jj show*"
        "jj sparse list*"
        "jj st"
        "jj status"
        "jj tag list*"
        "jj util config-schema"
        "jj version"
        "jj workspace list*"
        "jj workspace root*"

        "fj actions tasks*"
        "fj issue search*"
        "fj issue view*"
        "fj pr list*"
        "fj repo view*"
        "fj wiki contents*"
        "fj wiki view*"

        "git branch --list"
        "git diff*"
        "git log*"
        "git status*"

        "cargo check*"
        "cargo clippy*"
        "cargo fmt*"
        "cargo nextest*"
        "cargo test*"

        "curl http://localhost*"
        "curl -s http://localhost*"
        "curl -X GET http://localhost*"
        "curl -s -X GET http://localhost*"
        "curl -X POST http://localhost*"
        "curl -s -X POST http://localhost*"
        "curl -X PUT http://localhost*"
        "curl -s -X PUT http://localhost*"
        "curl -X DELETE http://localhost*"
        "curl -s -X DELETE http://localhost*"
      ];

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
              "*" = "ask";
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
              "web-reader_*" = "allow";
              "web-search-prime_*" = "allow";
              "nixos_*" = "allow";

              bash = genAttrs commands.allow (const "allow");
            };

            agent = {
              build = {
                mode = "primary";
                model = "zai-coding-plan/glm-5";

                permission.write."*" = "allow";
              };

              researcher = {
                mode = "primary";
                model = "zai-coding-plan/glm-5";
                description = "Read-only research primarily using the web";
              };

              explore = {
                mode = "subagent";
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
        name = "opencode-desktop-wrapped";
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
