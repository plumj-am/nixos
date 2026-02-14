let
  aiBase =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.generators) toJSON;
      inherit (lib.meta) getExe getExe';
      inherit (config.age) secrets;

      opencodePackage = pkgs.symlinkJoin {
        name = "opencode-wrapped";
        paths = [ inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = # sh
          ''
            wrapProgram $out/bin/opencode \
              --run 'export OPENCODE_EXPERIMENTAL=true export OPENCODE_ENABLE_EXA=1'
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

        files."opencode/opencode.jsonc" = {
          generator = toJSON { };
          value = {

            theme = "gruvbox";
            autoupdate = false;
            model = "zai-coding-plan/glm-5";

            permissions = {
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
                type = "primary";

                permission = {
                  write."*" = "allow";
                  bash."*" = "allow";
                  read."*" = "allow";

                  bash."curl*" = "ask";

                  read."*.env" = "deny";
                  read."*.envrc" = "deny";
                  bash."git push*" = "deny";
                  bash."git commit*" = "deny";
                  bash."jj*" = "deny";
                };
              };

              explore = {
                model = "z-ai-coding-plan/glm-4.7-flash";
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

            provider.zai-coding-plan.models = {
              "glm-5".options = {
                stream = true;
                thinking.type = "enabled";
                tool_stream = true;
                max_tokens = 128000;
              };
              "glm-4.7".options = {
                stream = true;
                thinking.type = "enabled";
              };
              "glm-4.7-flash".options = {
                stream = true;
              };
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
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModules = singleton {
        packages = [
          pkgs.codex
          pkgs.gemini-cli
          pkgs.qwen-code
        ];
      };
    };
in
{
  flake-file.inputs = {
    opencode = {
      url = "github:anomalyco/opencode";

      inputs.nixpkgs.follows = "os";
    };
  };

  flake.modules.nixos.ai = aiBase;
  flake.modules.darwin.ai = aiBase;

  flake.modules.nixos.ai-extra = aiExtra;
  flake.modules.darwin.ai-extra = aiExtra;
}
