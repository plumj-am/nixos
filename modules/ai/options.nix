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
              "command-code-key"
              "nvidia-nim-key"
              "codestral-key"
              "llm7-key"
              "ollama-key"
              "exa-key"
              "context7-key"
              "command-code-auth-json"
            ]
          // {
            litellm-environment = {
              sopsFile = ../../secrets/all/ai.yaml;
              owner = "litellm";
              group = "litellm";
              mode = "600";
            };
          };

      # "*" and " *" might not be necessary but tools sometimes differ in how
      # they handle them apparently. Once I'm sure, I'll just do this on the
      # fly where needed instead of duplicating everything here.
      config.ai.commands.bash.allow = [
        "ag*"
        "ag *"
        "awk*"
        "awk *"
        "bat*"
        "bat *"
        "cat*"
        "cat *"
        "command*"
        "command *"
        "date*"
        "date *"
        "echo*"
        "echo *"
        "false"
        "fd*"
        "fd *"
        "find*"
        "find *"
        "fzf*"
        "fzf *"
        "grep*"
        "grep *"
        "head*"
        "head *"
        "hyperfine*"
        "hyperfine *"
        "less*"
        "less *"
        "ls*"
        "ls *"
        "mkdir*"
        "mkdir *"
        "mktemp*"
        "mktemp *"
        "mv*"
        "mv *"
        "nl*"
        "nl *"
        "rg*"
        "rg *"
        "sg*"
        "sg *"
        "sort*"
        "sort *"
        "tail*"
        "tail *"
        "tree*"
        "tree *"
        "true"
        "uniq*"
        "uniq *"
        "wait*"
        "wait *"
        "wc*"
        "wc *"
        "which*"
        "which *"
        "xargs*"
        "xargs *"

        "jj bookmark list*"
        "jj bookmark list *"
        "jj commit -m*"
        "jj commit -m *"
        "jj commit --message*"
        "jj commit --message *"
        "jj desc -m*"
        "jj desc -m *"
        "jj desc --message*"
        "jj desc --message *"
        "jj describe -m*"
        "jj describe -m *"
        "jj describe --message*"
        "jj describe --message *"
        "jj diff*"
        "jj diff *"
        "jj evolog*"
        "jj evolog *"
        "jj file list*"
        "jj file list *"
        "jj file search*"
        "jj file search *"
        "jj file show*"
        "jj file show *"
        "jj git colocation status*"
        "jj git colocation status *"
        "jj git remote list*"
        "jj git remote list *"
        "jj git root*"
        "jj git root *"
        "jj help*"
        "jj help *"
        "jj interdiff*"
        "jj interdiff *"
        "jj log*"
        "jj log *"
        "jj new"
        "jj new -m*"
        "jj new -m *"
        "jj new --message*"
        "jj new --message *"
        "jj op diff*"
        "jj op diff *"
        "jj op log*"
        "jj op log *"
        "jj op show*"
        "jj op show *"
        "jj operation diff*"
        "jj operation diff *"
        "jj operation log*"
        "jj operation log *"
        "jj operation show*"
        "jj operation show *"
        "jj resolve --list*"
        "jj resolve --list *"
        "jj root*"
        "jj root *"
        "jj show*"
        "jj show *"
        "jj sparse list*"
        "jj sparse list *"
        "jj st*"
        "jj st *"
        "jj status*"
        "jj status *"
        "jj tag list*"
        "jj tag list *"
        "jj util config-schema*"
        "jj util config-schema *"
        "jj version*"
        "jj version *"
        "jj workspace list*"
        "jj workspace list *"
        "jj workspace root*"
        "jj workspace root *"

        "git branch --list"
        "git branch --show-current"
        "git diff*"
        "git diff *"
        "git log*"
        "git log *"
        "git show*"
        "git show *"
        "git status*"
        "git status *"

        "cabal build*"
        "cabal build *"

        "cargo build*"
        "cargo build *"
        "cargo check*"
        "cargo check *"
        "cargo clippy*"
        "cargo clippy *"
        "cargo doc*"
        "cargo doc *"
        "cargo fmt*"
        "cargo fmt *"
        "cargo nextest*"
        "cargo nextest *"
        "cargo test*"
        "cargo test *"
        "cargo tree*"
        "cargo tree *"

        "fasm*"
        "fasm *"

        "go build*"
        "go build *"
        "go fmt*"
        "go fmt *"
        "go test*"
        "go test *"

        "node --check*"
        "node --check *"
        "npx tsc*"
        "npx tsc *"

        "python3 -c*"
        "python3 -c *"

        "zig build*"
        "zig build *"

        "curl http://localhost*"
        "curl http://localhost *"
        "curl -s http://localhost*"
        "curl -s http://localhost *"
        "curl -X GET http://localhost*"
        "curl -X GET http://localhost *"
        "curl -s -X GET http://localhost*"
        "curl -s -X GET http://localhost *"
        "curl -X POST http://localhost*"
        "curl -X POST http://localhost *"
        "curl -s -X POST http://localhost*"
        "curl -s -X POST http://localhost *"
        "curl -X PUT http://localhost*"
        "curl -X PUT http://localhost *"
        "curl -s -X PUT http://localhost*"
        "curl -s -X PUT http://localhost *"
        "curl -X DELETE http://localhost*"
        "curl -X DELETE http://localhost *"
        "curl -s -X DELETE http://localhost*"
        "curl -s -X DELETE http://localhost *"

        "nix build*"
        "nix build *"
        "nix develop*"
        "nix develop *"
        "nix eval*"
        "nix eval *"
        "nix flake check*"
        "nix flake check *"
        "nix flake metadata*"
        "nix flake metadata *"
        "nix log*"
        "nix log *"
        "nix search*"
        "nix search *"

        "fj --help*"
        "fj --help *"
        "fj actions tasks*"
        "fj actions tasks *"
        "fj issue search*"
        "fj issue search *"
        "fj issue view*"
        "fj issue view *"
        "fj pr list*"
        "fj pr list *"
        "fj repo view*"
        "fj repo view *"
        "fj wiki contents*"
        "fj wiki contents *"
        "fj wiki view*"
        "fj wiki view *"
      ];
    };
}
