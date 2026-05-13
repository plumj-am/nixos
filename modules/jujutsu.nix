{
  flake.modules.common.jujutsu =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) theme;
    in
    {
      shellAliases = {
        lj = "lazyjj";
        ju = "jjui";
      };

      hjem.extraModule =
        { osConfig, config, ... }:
        {
          xdg.config.files."jj/config.toml" = {
            generator = pkgs.writers.writeTOML "jj-config.toml";
            value = {
              user.name = "PlumJam";
              user.email = "git@plumj.am";

              signing.key = "${config.directory}/.ssh/id";
              signing.backend = "ssh";
              signing.behavior = "drop";

              ui.conflict-marker-style = "snapshot";
              ui.default-command = "lg";
              ui.diff-editor = ":builtin";
              ui.diff-formatter = [
                "difft"
                "--color"
                "always"
                "$left"
                "$right"
              ];
              ui.merge-editor = "mergiraf";
              ui.editor = osConfig.environment.variables.EDITOR;
              ui.graph.style = "curved";
              ui.movement.edit = true;
              ui.pager = ":builtin";

              snapshot.max-new-file-size = "10MiB";

              gg = {
                default-mode = "web";
                web.default-port = 9999;
              };

              git = {
                sign-on-push = true; # Sign in bulk on push.
                subprocess = true;
                private-commits = "blacklist()"; # Prevent pushing WIP commits.
                write-change-id-header = true;
              };

              remotes.origin.auto-track-bookmarks = "glob:*";

              git.fetch = [
                "origin"
                "rad"
              ];
              git.push = "origin";

              aliases.".." = [
                "edit"
                "@-"
              ];
              aliases.",," = [
                "edit"
                "@+"
              ];

              aliases.a = [ "abandon" ];

              aliases.b = [ "bookmark" ];
              aliases.bs = [
                "bookmark"
                "set"
              ];
              aliases.bc = [
                "bookmark"
                "create"
              ];

              aliases.c = [ "commit" ];
              aliases.ci = [
                "commit"
                "--interactive"
              ];

              aliases.e = [ "edit" ];

              aliases.fetch = [
                "git"
                "fetch"
              ];
              aliases.f = [
                "git"
                "fetch"
              ];

              aliases.fr = [
                "new"
                "trunk()"
              ];
              aliases.fresh = [
                "new"
                "trunk()"
              ];

              aliases.r = [ "rebase" ];
              # Retrunk a series. Typically used as `jj retrunk -s ...`, and notably can be
              # used with open:
              # - jj retrunk -s 'all:roots(open())'
              aliases.retrunk = [
                "rebase"
                "-d"
                "trunk()"
              ];

              # Retrunk the current stack of work.
              aliases.reheat = [
                "rebase"
                "-d"
                "trunk()"
                "-s"
                "all:roots(trunk()..stack(@))"
              ];

              aliases.res = [ "resolve" ];
              aliases.resolve-ast = [
                "resolve"
                "--tool"
                "mergiraf"
              ];
              aliases.resa = [ "resolve-ast" ];

              aliases.s = [ "split" ];
              aliases.sm = [
                "split"
                "--message"
              ];

              aliases.sq = [ "squash" ];
              aliases.sqf = [
                "squash"
                "--from"
              ];
              aliases.sqi = [
                "squash"
                "--interactive"
              ];
              aliases.sqm = [
                "squash"
                "--message"
              ];
              aliases.sqmi = [
                "squash"
                "--interactive"
                "--message"
              ];
              # Take content from any change, and move it into @.
              # - jj consume xyz path/to/file`
              consume = [
                "squash"
                "--into"
                "@"
                "--from"
              ];
              # Eject content from @ into any other change.
              # - jj eject xyz --interactive
              eject = [
                "squash"
                "--from"
                "@"
                "--into"
              ];

              aliases.sh = [ "show" ];

              aliases.tug = [
                "bookmark"
                "move"
                "--from"
                "closest(@-)"
                "--to"
                "closest_pushable(@)"
              ];
              aliases.t = [ "tug" ];

              aliases.push = [
                "git"
                "push"
              ];
              aliases.p = [
                "git"
                "push"
              ];
              aliases.pb = [
                "git"
                "push"
                "--bookmark"
              ];

              aliases.init = [
                "git"
                "init"
                "--colocate"
              ];
              aliases.i = [
                "git"
                "init"
                "--colocate"
              ];

              aliases.clone = [
                "git"
                "clone"
                "--colocate"
              ];
              aliases.cl = [
                "git"
                "clone"
                "--colocate"
              ];

              aliases.d = [ "diff" ];
              aliases.ds = [ "diff --stat" ];

              aliases.l = [ "log" ];
              aliases.la = [
                "log"
                "--revisions"
                "::"
              ];
              aliases.ls = [
                "log"
                "--summary"
              ];
              aliases.lsa = [
                "log"
                "--summary"
                "--revisions"
                "::"
              ];
              aliases.lp = [
                "log"
                "--patch"
              ];
              aliases.lpa = [
                "log"
                "--patch"
                "--revisions"
                "::"
              ];
              aliases.lg = [
                "log"
                "--summary"
                "--revisions"
                "current()"
                "--limit=4"
              ];
              # Get all open stacks of work.
              aliases.open = [
                "log"
                "--revision"
                "open()"
              ];

              aliases.el = [ "evolog" ];
              aliases.ol = [
                "op"
                "log"
              ];

              aliases.w = [ "workspace" ];

              aliases.wa = [
                "workspace"
                "add"
              ];
              aliases.wf = [
                "workspace"
                "forget"
              ];
              aliases.wl = [
                "workspace"
                "list"
              ];
              aliases.wr = [
                "workspace"
                "rename"
              ];
              aliases.wro = [
                "workspace"
                "root"
              ];
              aliases.wu = [
                "workspace"
                "update-stale"
              ];

              revset-aliases = {
                "current()" = "ancestors(reachable(@, mutable()), 2)";
                "closest(to)" = "heads(::to & bookmarks())";
                "closest_pushable(to)" =
                  "heads(::to & ~description(exact:\"\") & (~empty() | merges()) & ~private())";

                "user(x)" = "author(x) | committer(x)";

                "wip()" = ''
                  description(glob:'wip:*') |
                  description(glob:'WIP:*') |
                  description(glob:'aba*') |
                  description(glob:'abandon*')
                '';
                "private()" = ''
                  description(glob:'private:*') |
                  description(glob:'PRIVATE:*') |
                  description('substring-i:"DO NOT MAIL"') |
                  conflicts() |
                  (empty() ~ merges())
                '';
                "pending()" = ".. ~ ::tags() ~ ::remote_bookmarks() ~ @ ~ private()";
                "blacklist()" = "wip() | private()";

                # By default, show the repo trunk, the remote bookmarks, and all remote tags. We
                # don't want to change these in most cases, but in some repos it's useful.
                "immutable_heads()" = "present(trunk()) | remote_bookmarks() | tags()";

                # trunk() by default resolves to the latest 'main'/'master' remote bookmark. May
                # require customization for repos like nixpkgs.
                "trunk()" = "latest((present(main) | present(master)) & remote_bookmarks())";

                # stack(x, n) is the set of mutable commits reachable from 'x', with 'n'
                # parents. 'n' is often useful to customize the display and return set for
                # certain operations. 'x' can be used to target the set of 'roots' to traverse,
                # e.g. @ is the current stack.
                "stack()" = "ancestors(reachable(@, mutable()), 2)";
                "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
                "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";
                # Shows all the current open stacks against the trunk (master/main).
                # 'n' is used the same way as above, to adjust depth.
                "stacks()" = "ancestors(reachable(trunk()::, mutable()), 2)";
                "stacks(n)" = "ancestors(reachable(trunk()::, mutable()), n)";

                # The current set of "open" works. It is defined as:
                #
                # - given the set of commits not in trunk, that are written by me,
                # - calculate the given stack() for each of those commits
                #
                # n = 1, meaning that nothing from `trunk()` is included, so all resulting
                # commits are mutable by definition.
                "open()" = "stack(trunk().. & mine(), 1)";

                # the set of 'ready()' commits. defined as the set of open commits, but nothing
                # that is blacklisted or any of their children.
                #
                # often used with gerrit, which you can use to submit whole stacks at once:
                #
                # - jj gerrit upload -r 'ready()' --dry-run
                "ready()" = "open() ~ blacklist()::";
              };

              # revsets.log = "present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 6)";
              revsets.log = "stack(@)";

              template-aliases."in_branch(commit)" = # python
                ''
                  commit.contained_in("immutable_heads()..bookmarks()")
                '';

              templates.log_node = # python
                ''
                  coalesce(
                    if(!self, label("elided", "~")),
                      label(
                        separate(" ",
                          if(current_working_copy, "working_copy"),
                          if(immutable, "immutable"),
                          if(conflict, "conflict"),
                        ),
                        coalesce(
                          if(current_working_copy, "◉"),
                          if(immutable, "◆"),
                          if(conflict, "×"),
                          if(self.contained_in("private()"), "◍"),
                          "○",
                        )
                      )
                  )
                '';

              templates.draft_commit_description = # python
                ''
                  concat(
                    coalesce(description, "\n"),
                    surround(
                      "\nJJ: This commit contains the following changes:\n", "",
                      indent("JJ:     ", diff.stat(72)),
                    ),
                    "\nJJ: ignore-rest\n",
                    diff.git(),
                  )
                '';

              # See ../jj-gerrit-config.toml for per-repo Gerrit config.
              templates.commit_trailers = # python
                ''
                  format_signed_off_by_trailer(self)
                '';

              templates.git_push_bookmark = # python
                ''
                  "patch/PlumJam-" ++ change_id.short()
                '';
            };
          };
          xdg.config.files."jjui/config.toml" = {
            generator = pkgs.writers.writeTOML "jjui-config.toml";
            value = {
              preview = {
                position = "right";
                show_at_start = true;
              };

              actions = singleton {
                name = "tug";
                lua = # lua
                  ''
                    jj_async("tug")
                    revisions.refresh()
                  '';
              };

              bindings = [
                {
                  key = singleton "T";
                  action = "tug";
                  scope = "revisions";
                  desc = "tug";
                }
                {
                  key = singleton "P";
                  action = "ui.preview_toggle_bottom";
                  scope = "revisions.details";
                  desc = "toggle preview bottom/right";
                }
              ];

              ui.colors."selected".bg = "#${theme.colors.base01}";
            };
          };
        };
    };

  flake.modules.common.jujutsu-extra =
    { pkgs, ... }:
    {
      hjem.extraModule = {
        packages = [
          pkgs.jujutsu
          pkgs.difftastic
          pkgs.mergiraf

          # TUI
          pkgs.lazyjj
          pkgs.jjui

          # GUI
          # pkgs.gg-jj
        ];
      };
    };
}
