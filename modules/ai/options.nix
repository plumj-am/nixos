{
  flake.modules.common.ai-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
    in
    {
      options.ai = {
        commands.bash.allow = mkOption {
          type = listOf str;
          default = [ ];
          description = ''
            bash command globs to allow in compatible AI tools
          '';
        };
      };

      config.ai.commands.bash.allow = [
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
        "jj commit -m*"
        "jj commit --message*"
        "jj desc -m*"
        "jj desc --message*"
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
        "jj new -m*"
        "jj new --message*"
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

        "git branch --list"
        "git branch --show-current"
        "git diff*"
        "git log*"
        "git status*"

        "cargo check*"
        "cargo clippy*"
        "cargo fmt*"
        "cargo nextest*"
        "cargo test*"
        "cargo tree*"

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
