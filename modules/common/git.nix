{ config, lib, pkgs, ... }: let
  inherit (lib) enabled;

  globalGitignore = pkgs.writeText "global-gitignore" ''
    .claude/
    mprocs.log
  '';
in {
  environment.shellAliases = {
    g   = "git";
    gi  = "git";
    gt  = "git";
    gti = "git";
  };

  home-manager.sharedModules = [
    {
      programs.gh = enabled {
        settings = {
          git_protocol = "ssh";

          editor = config.environment.variables.EDITOR;
        };
      };
    }
    (homeArgs: {
      programs.git = enabled {
        userName  = "PlumJam";
        userEmail = "git@plumj.am";

        signing.key           = "${homeArgs.config.home.homeDirectory}/.ssh/id";
        signing.signByDefault = true;

        lfs = enabled;

        difftastic = enabled;

        extraConfig = {
          init.defaultBranch = "master";

          log.date  = "iso";
          column.ui = "auto";

          commit.verbose = true;

          status.branch             = true;
          status.showStash          = true;
          status.showUntrackedFiles = "all";

          push.autoSetupRemote = true;

          pull.rebase                = true;
          rebase.autoStash           = true;
          rebase.missingCommitsCheck = "warn";
          rebase.updateRefs          = true;
          rerere.enabled             = true;

          fetch.fsckObjects    = true;
          receive.fsckObjects  = true;
          transfer.fsckObjects = true;

          branch.sort = "-committerdate";
          tag.sort    = "-taggerdate";

          core.compression  = 9;
          core.preloadindex = true;
          core.editor       = config.environment.variables.EDITOR;
          core.longpaths    = true;
          core.excludesfile = "${globalGitignore}";

          diff.algorithm  = "histogram";
          diff.colorMoved = "default";

          merge.conflictStyle = lib.mkDefault "zdiff3";

          commit.gpgSign    = true;
          tag.gpgSign       = true;
          gpg.format        = "ssh";
          credential.helper = "!gh auth git-credential";

          url."ssh://git@github.com/".insteadOf = "gh:";
        };

        aliases = {
          diff-stat = "diff --stat --ignore-space-change -r";

          f = "pull";
          p = "push";

          cm = "commit -m";
          ca = "commit --amend";

          aa = "add .";
          ap = "add -p";

          lg = "log --all --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";

          st  = "status -s";
          sta = "status";

          sw = "switch";

          oneln = "log --oneline";

          sus = "!f() { git branch --set-upstream-to $1; }; f";

          a = ''
            !f() { \
              for pattern in "$@"; do \
                matches=$(git ls-files | grep -i "$pattern"); \
                if [ -z "$matches" ]; then \
                  echo "no files found matching \"$pattern\""; \
                  continue; \
                fi; \
                if [ $(echo "$matches" | wc -l) -eq 1 ]; then \
                  git add "$matches"; \
                  echo "added: $matches"; \
                else \
                  echo "multiple matches for \"$pattern\":"; \
                  echo "$matches"; \
                  echo "$matches" | xargs git add; \
                  echo "added all matches"; \
                fi; \
              done; \
            }; f'';
          r = ''
            !f() { \
              if [ $# -eq 0 ]; then \
                git restore .; \
                echo "restored all files"; \
                return; \
              fi; \
              for pattern in "$@"; do \
                matches=$(git ls-files | grep -i "$pattern"); \
                if [ -z "$matches" ]; then \
                  echo "no files found matching \"$pattern\""; \
                  continue; \
                fi; \
                if [ $(echo "$matches" | wc -l) -eq 1 ]; then \
                  git restore "$matches"; \
                  echo "restored: $matches"; \
                else \
                  echo "multiple matches for \"$pattern\":"; \
                  echo "$matches"; \
                  printf "restore all? (y/n): "; \
                  read response; \
                  if echo "$response" | grep -q "^[Yy]"; then \
                    echo "$matches" | xargs git restore; \
                    echo "restored all matches"; \
                  fi; \
                fi; \
              done; \
            }; f'';
          rs = ''
            !f() { \
              if [ $# -eq 0 ]; then \
                git restore --staged .; \
                echo "unstaged all files"; \
                return; \
              fi; \
              for pattern in "$@"; do \
                matches=$(git ls-files | grep -i "$pattern"); \
                if [ -z "$matches" ]; then \
                  echo "no files found matching \"$pattern\""; \
                  continue; \
                fi; \
                if [ $(echo "$matches" | wc -l) -eq 1 ]; then \
                  git restore --staged "$matches"; \
                  echo "unstaged: $matches"; \
                else \
                  echo "multiple matches for \"$pattern\":"; \
                  echo "$matches"; \
                  printf "unstage all? (y/n): "; \
                  read response; \
                  if echo "$response" | grep -q "^[Yy]"; then \
                    echo "$matches" | xargs git restore --staged; \
                    echo "unstaged all matches"; \
                  fi; \
                fi; \
              done; \
            }; f'';
          d = ''
            !f() { \
              if [ $# -eq 0 ]; then \
                git diff; \
                return; \
              fi; \
              for pattern in "$@"; do \
                matches=$(git ls-files | grep -i "$pattern"); \
                if [ -z "$matches" ]; then \
                  echo "no files found matching \"$pattern\""; \
                  continue; \
                fi; \
                if [ $(echo "$matches" | wc -l) -eq 1 ]; then \
                  git diff "$matches"; \
                else \
                  echo "multiple matches for \"$pattern\":"; \
                  echo "$matches"; \
                  echo "$matches" | xargs git diff; \
                fi; \
              done; \
            }; f'';
          ds = ''
            !f() { \
              if [ $# -eq 0 ]; then \
                git diff --staged; \
                return; \
              fi; \
              for pattern in "$@"; do \
                matches=$(git ls-files | grep -i "$pattern"); \
                if [ -z "$matches" ]; then \
                  echo "no files found matching \"$pattern\""; \
                  continue; \
                fi; \
                if [ $(echo "$matches" | wc -l) -eq 1 ]; then \
                  git diff --staged "$matches"; \
                else \
                  echo "multiple matches for \"$pattern\":"; \
                  echo "$matches"; \
                  echo "$matches" | xargs git diff --staged; \
                fi; \
              done; \
            }; f'';
        };
      };
    })
  ];
}
