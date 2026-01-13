{
  config.flake.modules.hjem.git =
    { lib, ... }:
    let
      inherit (lib) mkDefault;
    in
    {
      rum.programs.git = {
        enable = true;

        integrations.difftastic.enable = true;

        ignore = # .gitignore
          ''
            .claude/
            mprocs.log
          '';

        # TODO: commit signing
        settings = {
          user.name = "PlumJam";
          user.email = "git@plumj.am";

          init.defaultBranch = "master";

          log.date = "iso";
          column.ui = "auto";

          commit.verbose = true;

          status.branch = true;
          status.showStash = true;
          status.showUntrackedFiles = "all";

          push.autoSetupRemote = true;

          pull.rebase = true;
          rebase.autoStash = true;
          rebase.missingCommitsCheck = "warn";
          rebase.updateRefs = true;
          rerere.enabled = true;

          fetch.fsckObjects = true;
          receive.fsckObjects = true;
          transfer.fsckObjects = true;

          branch.sort = "-committerdate";
          tag.sort = "-taggerdate";

          core.compression = 9;
          core.preloadindex = true;
          # TODO
          # core.editor       = config.environment.variables.EDITOR;
          core.longpaths = true;

          diff.algorithm = "histogram";
          diff.colorMoved = "default";

          merge.conflictStyle = mkDefault "zdiff3";

          commit.gpgSign = true;
          tag.gpgSign = true;
          gpg.format = "ssh";
          # TODO: Check how to use many. This doesn't work.
          credential.helper = # .gitconfig
            ''
              "!gh auth git-credential"
              "cache --timeout 21600" # 6 hours
              "oauth"
              "oauth -device"
            '';

          core.sshCommand = "ssh -i ~/.ssh/id";

          url."ssh://git@github.com/".insteadOf = "gh:";
        };
      };
    };
}
