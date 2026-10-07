{ self, ... }:
{
  flake.modules.common.default.imports = [
    self.modules.common.git
    self.modules.common.jujutsu
    self.modules.common.pijul

    self.modules.common.diff-formatter
    self.modules.common.jj-stack
    self.modules.common.jjui
    self.modules.common.watchman
    self.modules.common.weave
  ];

  flake.modules.common.git =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
    in
    {
      shellAliases.git-graph = ''git log --graph --full-history --pretty=format:"%h%  %d%x20%s"'';

      environment.systemPackages = [
        pkgs.gh
        pkgs.gitMinimal
        pkgs.difftastic
        pkgs.git-credential-oauth
      ];

      hjemModule = {
        xdg.config.files."git/ignore".text = # .gitignore
          ''
            .claude/
            mprocs.log
          '';

        xdg.data.files."gh/extensions/gh-stack".source = "${pkgs.gh-stack}/bin";

        xdg.config.files."git/config" = {
          generator = lib.generators.toGitINI;
          value = {
            user.name = "PlumJam";
            user.email = "git@plumj.am";

            init.defaultBranch = "master";

            log.date = "iso";
            column.ui = "auto";

            alias = {
              patch = "push rad HEAD:refs/patches";
            };

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
            core.editor = "${config.environment.variables.EDITOR}";
            core.longpaths = true;

            diff.algorithm = "histogram";
            diff.colorMoved = "default";
            diff.external = getExe pkgs.difftastic;
            diff.tool = "difftastic";
            difftool.difftastic.cmd = "${getExe pkgs.difftastic} $LOCAL $REMOTE";

            merge.conflictStyle = "zdiff3";

            commit.gpgSign = true;
            tag.gpgSign = true;
            gpg.format = "ssh";

            user.signingkey = "~/.ssh/id";

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
    };

  flake.modules.common.pijul =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = singleton pkgs.pijul;

      hjemModule =
        { config, ... }:
        {
          xdg.config.files."pijul/config.toml" = {
            generator = pkgs.writers.writeTOML "pijul-config.toml";
            value = {
              colors = "always";
              pager = "auto";
              unrecord_changes = 1;

              author = {
                name = "plumjam";
                full_name = "PlumJam";
                email = "pijul@plumj.am";
                key_path = "${config.directory}/.ssh/id.pub";
              };
            };
          };
        };
    };

  flake.modules.common.jujutsu =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkBefore mkDefault;

      jujutsu = inputs.jujutsu.packages.${pkgs.stdenv.hostPlatform.system}.jujutsu;
    in
    {
      environment.systemPackages = singleton jujutsu;

      hjemModule =
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
              ui.editor = osConfig.environment.variables.EDITOR;
              ui.graph.style = "curved";
              ui.movement.edit = true;
              ui.pager = mkDefault ":builtin";

              snapshot.auto-update-stale = true;
              snapshot.max-new-file-size = "10MiB";

              git = {
                executable-path = getExe pkgs.gitMinimal;
                subprocess = true;

                colocate = true;

                sign-on-push = true; # Sign in bulk on push.
                private-commits = "blacklist()"; # Prevent pushing WIP commits.
                write-change-id-header = true;
              };

              remotes.origin.auto-track-bookmarks = "glob:*";

              git.fetch = [ "origin" ];
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
                "immutable_heads()" =
                  ''(present(trunk()) | remote_bookmarks() | tags()) ~ bookmarks(glob:"change/*") ~ bookmarks(glob:"jj-stack/*")'';

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

              revsets.log = "present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 6)";
              # revsets.log = "work_ui()"; # Do this in per repo config.

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

          xdg.config.files."nushell/config.nu".text =
            mkBefore
              # nu
              ''
                $env.config.hooks.env_change.PWD = (
                  $env.config.hooks.env_change.PWD? | default [] | append [
                    # For jj workspaces so git stuff still works.
                    {||
                      $env.GIT_DIR = match (${getExe jujutsu} git root | complete) {
                        {exit_code: 0, stdout: $out} => { $out | str trim }
                        _ => { hide-env --ignore-errors GIT_DIR }
                      }
                    }
                  ]
                )
              '';
        };
    };

  flake.modules.common.jj-stack =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkDefault;

      jjStack = self.packages.${pkgs.stdenv.hostPlatform.system}.jj-stack;
    in
    {
      environment.systemPackages = singleton jjStack;

      hjemModule = {
        xdg.config.files."jj/config.toml" = {
          generator = mkDefault <| pkgs.writers.writeTOML "jj-config.toml";
          value = {
            jj-stack.branch_prefix = "jj-stack";
            aliases.stack = [
              "util"
              "exec"
              "--"
              (getExe jjStack)
            ];
          };
        };
      };
    };

  flake.modules.common.jjui =
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
      environment.systemPackages = singleton pkgs.jjui;

      hjemModule = {
        xdg.config.files."jjui/config.toml" = {
          generator = pkgs.writers.writeTOML "jjui-config.toml";
          value = {
            preview = {
              position = "bottom";
              show_at_start = true;
            };

            ui = {
              mouse_support = false;
              auto_refresh_interval = 30;
              flash_message_display_seconds = 15;
              colors."selected".bg = "#${theme.colors.base01}";
            };

            revisions.revset = "all()";

            bookmark.interactive_bookmark_pane = true;

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
          };
        };
      };
    };

  flake.modules.common.diff-formatter =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (pkgs) hunk;
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;

      difft =
        pkgs.writeShellScriptBin "difft" # bash
          ''
            exec ${getExe pkgs.difftastic} --background ${if config.theme.isDark then "dark" else "light"} "$@"
          '';

      inherit (lib.modules) mkDefault;
    in
    {
      environment.systemPackages = [
        difft
        hunk
      ];

      hjemModule = {
        xdg.config.files."jj/config.toml" = {
          generator = mkDefault <| pkgs.writers.writeTOML "jj-config.toml";
          value = {
            "--scope" = singleton {
              "--when".environments = singleton "JJUI";
              ui.diff-formatter = [
                (getExe difft)
                "--color"
                "always"
                "$left"
                "$right"
              ];
            };

            ui = {
              diff-formatter = ":git";
              pager = [
                (getExe hunk)
                "pager"
              ];
            };
          };
        };
      };
    };

  flake.modules.common.weave =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe';
      inherit (lib.modules) mkDefault;
    in
    {
      environment.systemPackages = singleton pkgs.weave;

      hjemModule = {
        xdg.config.files."jj/config.toml" = {
          generator = mkDefault <| pkgs.writers.writeTOML "jj-config.toml";
          value = {
            aliases = {
              resa = [ "resolve-ast" ];
              resolve-ast = [
                "resolve"
                "--tool"
                "weave"
              ];
            };

            ui.merge-editor = "weave";

            merge-tools.weave = {
              program = getExe' pkgs.weave "weave-driver";
              merge-args = [
                "$base"
                "$left"
                "$right"
                "-o"
                "$output"
                "-l"
                "$marker_length"
                "-p"
                "$path"
              ];
              merge-conflict-exit-codes = [ 1 ];
              merge-tool-edits-conflict-markers = true;
              conflict-marker-style = "git";
            };
          };
        };
      };
    };

  flake.modules.common.watchman =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkDefault;
    in
    {
      environment.systemPackages = singleton pkgs.watchman;

      hjemModule = {
        xdg.config.files."watchman/watchman.json" = {
          generator = pkgs.writers.writeJSON "watchman-watchman.json";
          value = {
            ignore_dirs = [
              ".direnv"
              "node_modules"
              "target"
            ];
          };
        };

        xdg.config.files."jj/config.toml" = {
          generator = mkDefault <| pkgs.writers.writeTOML "jj-config.toml";
          value = {
            fsmonitor = {
              backend = "watchman";
              fsmonitor.watchman.register-snapshot-trigger = true;
            };
          };
        };
      };
    };
}
