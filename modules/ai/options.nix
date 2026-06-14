{
  flake.modules.common.ai-options =
    { lib, config, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.attrsets) genAttrs;
      inherit (lib.trivial) flip const;
      inherit (lib.options) mkOption mkEnableOption;
      inherit (lib.types) listOf str;
    in
    {
      options.ai = {
        secrets = mkEnableOption "include AI secrets with this system/module";

        commands.bash.allow = mkOption {
          type = listOf str;
          default = [ ];
          description = ''
            bash command globs to allow in compatible AI tools
          '';
        };
      };

      config.sops.secrets =
        mkIf config.ai.secrets
        <|
          flip genAttrs
            (const {
              sopsFile = ../../secrets/all/ai.yaml;
              owner = "jam";
              group = "users";
              mode = "600";
            })
            [
              "opencode-go-key"
              "command-code-key"
              "nvidia-nim-key"
              "codestral-key"
              "llm7-key"
              "openrouter-key"
              "ollama-key"
              "sambanova-key"
              "exa-key"
              "context7-key"
            ]
          // {
            litellm-environment = {
              sopsFile = ../../secrets/all/ai.yaml;
              owner = "litellm";
              group = "litellm";
              mode = "600";
            };
          };

      config.ai.commands.bash.allow = [
        "ag*"
        "awk*"
        "bat*"
        "cat*"
        "command*"
        "date*"
        "echo*"
        "false"
        "fd*"
        "find*"
        "fzf*"
        "grep*"
        "head*"
        "hyperfine*"
        "less*"
        "ls*"
        "mktemp*"
        "nl*"
        "rg*"
        "sg*"
        "sort*"
        "tail*"
        "tree*"
        "true"
        "uniq*"
        "wait*"
        "wc*"
        "which*"
        "xargs*"

        "jj bookmark list*"
        "jj commit -m*"
        "jj commit --message*"
        "jj desc -m*"
        "jj desc --message*"
        "jj describe -m*"
        "jj describe --message*"
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
        "jj new"
        "jj new -m*"
        "jj new --message*"
        "jj op diff*"
        "jj op log*"
        "jj op show*"
        "jj operation diff*"
        "jj operation log*"
        "jj operation show*"
        "jj resolve --list*"
        "jj root*"
        "jj show*"
        "jj sparse list*"
        "jj st*"
        "jj status*"
        "jj tag list*"
        "jj util config-schema*"
        "jj version*"
        "jj workspace list*"
        "jj workspace root*"

        "git branch --list"
        "git branch --show-current"
        "git diff*"
        "git log*"
        "git show*"
        "git status*"

        "cargo build*"
        "cargo check*"
        "cargo clippy*"
        "cargo doc*"
        "cargo fmt*"
        "cargo nextest*"
        "cargo test*"
        "cargo tree*"

        "fasm*"

        "go build*"
        "go fmt*"
        "go test*"

        "node --check*"
        "npx tsc*"

        "zig build*"

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

        "nix build*"
        "nix develop*"
        "nix eval*"
        "nix flake check*"
        "nix flake metadata*"
        "nix log*"
        "nix search*"

        "fj --help*"
        "fj actions tasks*"
        "fj issue search*"
        "fj issue view*"
        "fj pr list*"
        "fj repo view*"
        "fj wiki contents*"
        "fj wiki view*"
      ];
    };
}
