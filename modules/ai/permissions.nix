{ self, ... }:
{
  flake.modules.common.default = self.modules.common.ai-permissions;
  flake.modules.common.ai-permissions =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) filter;
      inherit (lib.modules) mkIf;
      inherit (lib.strings) hasSuffix removeSuffix;
      inherit (lib.trivial) const flip;
    in
    {
      config = {
        sops.secrets =
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
                "commandcode-1-key"
                "commandcode-2-key"
                "exa-key"
                "context7-key"
                "opencode-go-key"
              ];

        ai.commands.bash.allow =
          let
            commands = [
              "ag*"
              "awk*"
              "bat*"
              "cat*"
              "command*"
              "date*"
              "diff*"
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
              "mkdir*"
              "mktemp*"
              "mv*"
              "nu*"
              "nl*"
              "rg*"
              "rm"
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

              "cabal build*"

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

              "python3 -c*"

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
          in
          # handle both " *" and "*" endings for allow lists
          # no harm in doing it here for all agents
          commands ++ (commands |> filter (hasSuffix "*") |> map (c: removeSuffix "*" c + " *"));
      };
    };
}
