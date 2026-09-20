{ self, ... }:
{
  flake.modules.common.default = self.modules.common.ai-options;
  flake.modules.common.ai-options =
    { lib, config, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.attrsets) genAttrs;
      inherit (lib.trivial) flip const;
      inherit (lib.options) mkOption mkEnableOption;
      inherit (lib.types) listOf str ints;
      inherit (lib.strings) removeSuffix hasSuffix;
      inherit (lib.lists) filter;
      skillTypes = import ../../options/skills.nix { inherit lib; };
    in
    {
      options.ai = {
        secrets = mkEnableOption "include AI secrets with this system/module";

        subs.commandcode.active = mkOption {
          type = ints.between 1 2;
          description = ''
            which commandcode subscription to use in AI tools
          '';
        };

        commands.bash.allow = mkOption {
          type = listOf str;
          default = [ ];
          description = ''
            bash command globs to allow in compatible AI tools
          '';
        };

        skills.gh = mkOption {
          type = listOf skillTypes.repoSkill;
          default = [ ];
          description = ''
            skills to install from github
          '';
        };
        skills.npm = mkOption {
          type = listOf skillTypes.repoSkill;
          default = [ ];
          description = ''
            skills to install from npm
          '';
        };
        skills.local = mkOption {
          type = listOf skillTypes.localSkill;
          default = [ ];
          description = ''
            skills to install from local sources
          '';
        };
      };

      config = {
        ai.skills.npm = [
          {
            repo = "mattpocock/skills";
            skills = [
              "grilling"
              "grill-me"
              "grill-with-docs"
            ];
          }
        ];
        ai.skills.gh = [
          {
            repo = "bos/jj-stack";
            skills = [
              "jj-stack@7d8a68f3de6273e4c08c250f8aae1b1c9a2" # v1.3.0 (matches ../jujutsu.nix)
            ];
          }
          {
            repo = "github/gh-stack";
            skills = [
              "gh-stack@2bd699a544a09cb5c45a013d03416e0894b0454e" # v0.1.1
            ];
          }
        ];
        ai.skills.local = [
          {
            name = "pr-review-cron";
            skillmd = ''
              ---
              name: pr-review-cron
              description: Review pull requests for bugs, performance, security issues, and code quality
              ---

              # Code Review Guidelines

              When reviewing a pull request:

              ## What to Check
              1. **Bugs** — Logic errors, off-by-one, null/undefined handling
              2. **Security** — Injection, auth bypass, secrets in code, SSRF
              3. **Performance** — N+1 queries, unbounded loops, memory leaks
              4. **Style** — Naming conventions, dead code, missing error handling
              5. **Tests** — Are changes tested? Do tests cover edge cases?

              ## Output Format
              For each finding:
              - **File:Line** — exact location (hyperlinked!)
              - **Severity** — Critical / Warning / Suggestion
              - **What's wrong** — one sentence
              - **Fix** — how to fix it

              ## Rules
              - Be specific. Quote the problematic code.
              - Don't flag style nitpicks unless they affect readability.
              - If the PR looks good, say so. Don't invent problems.
              - End with: APPROVE / REQUEST_CHANGES / COMMENT
            '';
          }
        ];

        ai.subs.commandcode.active = 2;

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
