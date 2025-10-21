{ pkgs, lib, config, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktop {
  unfree.allowedNames = [ "claude-code" "codex" ];

  environment.shellAliases = {
    claude = "claude --continue --fork-session";
    codex  = "codex resume --ask-for-approval untrusted";
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
    group = "users";
    mode = "0400";
  };

  home-manager.sharedModules = [{
    programs.claude-code = enabled {
      package = pkgs.symlinkJoin {
        name = "claude-code-wrapped";
        paths = [ pkgs.claude-code ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
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
          "Edit(PROJECT_MANAGER.md)"
          "Edit(CURRENT_TASK.md)"
          "Edit(STATE.md)"
          "Update(PROJECT_MANAGER.md)"
          "Update(CURRENT_TASK.md)"
          "Update(STATE.md)"
        ];

        deny = [
          "Read(*.env)"
          "Read(*.envrc)"
          "Bash(git push:*)"
          "Bash(git commit:*)"
        ];
      };
    };
  }];
}
