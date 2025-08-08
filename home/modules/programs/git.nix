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
      cm = "commit -m";
      aa = "add .";
      ap = "add -p";
      lg = "log --all --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      st = "status";
      sw = "switch";
      oneln = "log --oneline";
      sus = "!f() { git branch --set-upstream-to $1; }; f";
    };
  };
}
