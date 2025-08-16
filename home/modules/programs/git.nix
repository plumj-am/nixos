{
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
  };

  programs.git = {
    enable = true;
    userName = "James Plummer";
    userEmail = "jamesp2001@live.co.uk";

    signing = {
      key = "58805BF7676222B4";
      signByDefault = true;
    };

    lfs.enable = true;

    difftastic.enable = true;

    extraConfig = {
      init.defaultBranch = "master";

      log.date = "iso";
      column.ui = "auto";

      commit.verbose = true;
      commit.gpgSign = true;
      tag.gpgSign = true;

      status = {
        branch = true;
        showStash = true;
        showUntrackedFiles = "all";
      };

      pull.rebase = true;
      push.autoSetupRemote = true;

      rebase = {
        autoStash = true;
        missingCommitsCheck = "warn";
        updateRefs = true;
      };
      rerere.enabled = true;

      fetch.fsckObjects = true;
      receive.fsckObjects = true;
      transfer.fsckObjects = true;

      branch.sort = "-committerdate";
      tag.sort = "-taggerdate";

      core = {
        compression = 9;
        preloadindex = true;
        editor = "nvim";
        longpaths = true;
        # pager = "delta";
        excludesfile = "~/.global_gitignore";
      };

      diff.algorithm = "histogram";
      diff.colorMoved = "default";

      # interactive.diffFilter = "delta --color-only";
      #
      # delta = {
      #   navigate = true;
      #   dark = true;
      # };

      merge.conflictStyle = "zdiff3";

      credential.helper = "!gh auth git-credential";

      "url \"http://github.com/\"".insteadOf = "gh:";
    };

    aliases = {
      diff-stat = "diff --stat --ignore-space-change -r";
      p = "pull";
      P = "push";
      cm = "commit -m";
      ca = "commit --amend";
      aa = "add .";
      ap = "add -p";
      lg = "log --all --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      st = "status -s";
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
                        printf "add all? (y/n): "; \
                        read response; \
                        if echo "$response" | grep -q "^[Yy]"; then \
                            echo "$matches" | xargs git add; \
                            echo "added all matches"; \
                        fi; \
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
                        printf "diff all? (y/n): "; \
                        read response; \
                        if echo "$response" | grep -q "^[Yy]"; then \
                            echo "$matches" | xargs git diff; \
                        fi; \
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
                        printf "diff staged all? (y/n): "; \
                        read response; \
                        if echo "$response" | grep -q "^[Yy]"; then \
                            echo "$matches" | xargs git diff --staged; \
                        fi; \
                    fi; \
                done; \
            }; f'';
    };
  };
}
