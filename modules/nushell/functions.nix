{ self, ... }:
{
  flake.modules.common.nushell = self.modules.common.nushell-functions;
  flake.modules.common.nushell-functions =
    {
      pkgs,
      ...
    }:
    {
      hjemModule = {
        xdg.config.files."nushell/config.nu".text = # nu
          "source ${pkgs.writeText "nushell-functions.nu" ''
            def "cargo search" [query: string, --limit: int = 10]: nothing -> table {
              cargo search $query --limit $limit
              | lines
              | each {|line|
                if ($line =~ "#") {
                  $line | parse --regex '(?P<name>.+) = "(?P<version>.+)" +# (?P<description>.+)'
                } else {
                  $line | parse --regex '(?P<name>.+) = "(?P<version>.+)"'
                }
              }
              | flatten
            }

            def "cargo update-all" [--force]: nothing -> nothing {
              # nu-lint-ignore: non_final_failure_check
              cargo install --list
              | parse "{package} v{version}:"
              | get package
              | each {|p|
                if $force {
                  cargo install --locked --force $p
                } else {
                  cargo install --locked $p
                }
              }
            }

            def pwd []: any -> string {
              $env.PWD | str replace $nu.home-dir '~'
            }

            # nu-lint-ignore: print_and_return_data
            def "git summary" [--count(-n): int = 10]: nothing -> nothing {
              try {
                git log $"--pretty=%h»¦«%aN»¦«%s»¦«%aD" $"-($count)"
                | lines
                | split column »¦« sha1 committer desc merged_at
                | histogram committer merger
                | sort-by merger
                | reverse
                | table --index 1 # start index from 1
              } catch { print "Error: Make sure you're in a git repository" }
            }

            def "review" [
              pull_request?: int, # PR to review - if unset, all reviewable PRs are listed
              --repo(-r): string = "grove-systems/grove" # full owner/repo reference
            ] {
              if $pull_request == null {
                print "Fetching PRs..."

                let pr_list = gh pr list --repo $repo --limit 9999 --json author,number,reviewRequests,updatedAt
                | from json
                | where reviewRequests != []
                | par-each --keep-order {|pr|
                  {
                    '#':       $pr.number
                    reviewers: ($pr.reviewRequests | get login | str join ", ")
                    author:    $pr.author.login
                    updated:   ($pr.updatedAt | into datetime | format date '%Y-%m-%d %H:%M')
                  }
                }
                | sort-by updated

                if ($pr_list | is-not-empty) {
                  print $"The following ($pr_list | length) PRs are waiting for review:"

                  $pr_list | table --index false
                } else {
                  print "No PRs to review."
                }
              } else {
                gh pr diff $pull_request --patch --repo $repo | hunk patch -
              }
            }

            def loop-check [] {
              loop {
                # `jj resolve --list` exits non-zero when there are no conflicts
                let conflicts = jj resolve --list | complete
                if $conflicts.exit_code == 0 {
                  let result = jj resolve --tool mergiraf | complete
                  if $result.exit_code != 0 {
                    error make $"conflict resolution failed:(char nl)($result.stderr)"
                  }
                }

                trim

                nix run .#formatter.x86_64-linux

                let check = nix run .#graph -- check | complete
                if $check.exit_code != 0 {
                  print $"stdout:(char nl)($check.stdout)"
                  print $"stderr:(char nl)($check.stderr)"
                  error make "graph check failed"
                }

                let res = jj edit @+ | complete
                # no more revisions to move to -> we're done
                if ($res.stderr | str contains "Revset `@+` didn't resolve to any revisions") { break }

                if $res.exit_code != 0 { error make $"`jj edit @+` failed: ($res.stderr)" }
              }
            }
          ''}";
      };
    };
}
