{
  flake.modules.hjem.git =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkDefault;
    in
    {
      packages = [
        pkgs.gh
        pkgs.git-credential-oauth
      ];
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
          core.editor = "${config.environment.sessionVariables.EDITOR}";
          core.longpaths = true;

          diff.algorithm = "histogram";
          diff.colorMoved = "default";

          merge.conflictStyle = mkDefault "zdiff3";

          commit.gpgSign = true;
          tag.gpgSign = true;
          gpg.format = "ssh";

          core.sshCommand = "ssh -i ~/.ssh/id";

          url."ssh://git@github.com/".insteadOf = "gh:";

          include.path = "credentials";
        };
      };
      xdg.config.files."git/credentials".text = # ini
        ''
          [credential]
            helper=cache --timeout 21600
            helper=oauth
            helper=oauth -device
            helper=!gh auth git-credential
          [credential "https://git.plumj.am"]
            oauthClientId=a4792ccc-144e-407e-86c9-5e7d8d9c3269
            oauthAuthURL=/login/oauth/authorize
            oauthTokenURL=/login/oauth/access_token
        '';
    };
}
