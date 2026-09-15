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
            def zellij-update-tabname []: nothing -> nothing {
              if "ZELLIJ" in $env {
                let tab_name = if (pwd) == $env.HOME {
                  "~"
                } else {
                 (pwd | path parse | get stem)
                }

                zellij action rename-tab $tab_name
              }
            }

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
          ''}";
      };
    };
}
