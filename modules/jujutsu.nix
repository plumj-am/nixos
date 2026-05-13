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
              aliases.consume = [
                "squash"
                "--into"
                "@"
                "--from"
              ];
              # Eject content from @ into any other change.
              # - jj eject xyz --interactive
              aliases.eject = [
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
              aliases.ds = [
                "diff"
                "--stat"
              ];

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

                # Collapsed trunk - removes full ancestry
                "trunk_head()" = "heads(trunk())";

                # All current open stacks of work
                "work()" = "mine() & mutable() & ~immutable_heads()";

                # Same as above but shows parents for a nice UI view
                "work_ui()" = "work() | trunk_head()";

                # All commits in current stack (linearized by @ ancestry)
                # "stack_members()" = "ancestors(@, 1000) & work()";
                # This version should handle detached commits better and does not assume
                # @ is somewhere in the stack.
                "stack_members()" = "ancestors(closest(work()), 1000) & work()";

                # Root of current stack
                # ::@ & enforces linearity
                # Otherwise, it can be ambiguous and break if history is not linear.
                "stack_root()" = "roots(::@ & stack_members())";

                # Entire current stack
                "stack()" = "stack_members()";

                # Useful derived forms
                "stack_tip()" = "heads(stack())";

                # Open changes = current stack only
                "open()" = "stack()";

                # Ready to push
                "ready()" = "open() ~ blacklist()";
              };

              # revsets.log = "present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 6)";
              revsets.log = "work_ui()";

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
                position = "bottom";
                show_at_start = true;
              };

              actions = [
                {
                  name = "tug";
                  lua = # lua
                    ''
                      jj_async("tug")
                      revisions.refresh()
                    '';
                }
                {
                  name = "gerrit-upload";
                  lua = # lua
                    ''
                      local args = input({
                        title = "jj gerrit upload <args>",
                        prompt = "Arguments: "
                      })

                      if args ~= nil and args ~= "" then
                      local argv = {"gerrit", "upload"}
                        for arg in string.gmatch(args, "%S+") do
                          table.insert(argv, arg)
                        end

                        jj_async(argv)
                        revisions.refresh()
                      end

                    '';
                }
              ];

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
                {
                  key = singleton "G";
                  action = "gerrit-upload";
                  scope = "revisions";
                  desc = "gerrit upload";
                }
              ];

              ui.flash_message_display_seconds = 15;
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
