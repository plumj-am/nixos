{ pkgs, lib, config, ... }: let
  inherit (lib) enabled disabled;
in {
  unfree.allowedNames = [ "claude-code" "codex" ];

  environment.shellAliases = {
    claude = "claude --continue --fork-session";
    codex  = "codex resume --ask-for-approval untrusted";
    oc     = "opencode --continue";
  };

  environment.systemPackages = [
    pkgs.claude-code
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
    programs.claude-code = disabled {
      package = pkgs.symlinkJoin {
        name        = "claude-code-wrapped";
        paths       = [ pkgs.claude-code ];
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

        allow = [
          "Edit(PROJECT.md)"
          "Edit(CURRENT.md)"
          "Edit(STATE.md)"
          "Update(PROJECT.md)"
          "Update(CURRENT.md)"
          "Update(STATE.md)"
          "Bash(curl http://localhost:*)"
          "Bash(curl -X GET http://localhost:*)"
        ];

        deny = [
          "Read(*.env)"
          "Read(*.envrc)"
          "Bash(git push:*)"
          "Bash(git commit:*)"
        ];
      };
    };

    programs.opencode = enabled {
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
        };
      };
    };
  }];
}
