{ config, pkgs, lib, ... }: let
  inherit (lib) enabled mkAfter;

in {
  environment.shellAliases = {
    j  = "jj";
    lj = "lazyjj";
  };

  environment.systemPackages = [ pkgs.lazyjj ];

  home-manager.sharedModules = [
    {
      programs.difftastic = enabled;

      programs.mergiraf = enabled;

      programs.nushell.configFile.text = mkAfter /* nu */ ''
        def --wrapped jpa [
          --revisions (-r): string = "@" # The revision(s) to pass to `jj git push`
          ...rest: string # Any other args to pass to `jj git push`
        ] {
          let remotes       = ["origin" "forgejo"]
          let remotes_full  = (jj git remote list | lines | split column " " name url)
          let remotes_names = ($remotes_full | get name)
          for remote in $remotes {
            if $remote in $remotes_names {
              print $"(ansi purple)[Pusher](ansi rst) Pushing to ($remote)."
              jj git push ...$rest --revisions $revisions --remote $remote
            } else if $remote == "forgejo" {
              print $"(ansi purple)[Pusher](ansi rst) Forgejo remote not found."
              let input = (input --numchar 1 $"(ansi purple)[Pusher](ansi rst) Attempt to add forgejo remote? \(y/n\) ")
              if ($input | str downcase | str starts-with "y") {
                let origin_url = ($remotes_full | where name == "origin" | get url | first)
                let repo_name = ($origin_url | split row "/" | last)
                let forgejo_url = $"https://git.plumj.am/plumjam/($repo_name)"
                print $"(ansi purple)[Pusher](ansi rst) Adding forgejo remote: ($forgejo_url)"
                jj git remote add forgejo $forgejo_url
                print $"(ansi purple)[Pusher](ansi rst) Added forgejo remote, pushing..."
                jj git push ...$rest --revisions $revisions --remote $remote
              } else {
                print $"(ansi purple)[Pusher](ansi rst) Skipping forgejo remote setup."
              }
            } else {
              print $"(ansi purple)[Pusher](ansi rst) Remote ($remote) not available, skipping."
            }
          }
        }
      '';
    }
    (homeArgs: let
      config' = homeArgs.config;
    in {
      # credit to https://github.com/rgbcube/ncc for most of this
      programs.jujutsu = enabled {
        settings = {
          user.name  = config'.programs.git.settings.user.name;
          user.email = config'.programs.git.settings.user.email;

          signing.key      = "${homeArgs.config.home.homeDirectory}/.ssh/id";
          signing.backend  = "ssh";
          signing.behavior = "own";

          ui.conflict-marker-style = "snapshot";
          ui.default-command       = "lg";
          ui.diff-editor           = ":builtin";
          ui.diff-formatter        = [ "difft" "--color" "always" "$left" "$right" ];
          ui.editor                = config.environment.variables.EDITOR;
          ui.graph-style           = "square";
          ui.movement.edit         = true;
          ui.pager                 = ":builtin";

          snapshot.max-new-file-size = "10MiB";

          lazyjj.highlight-color = "#f2e5bc";

          git.sign-on-push        = true; # sign in bulk on push
          git.auto-local-bookmark = true;

          git.subprocess = true;

          git.fetch = [ "origin" "forgejo" ];
          git.push  = "origin";

          aliases.".." = [ "edit" "@-" ];
          aliases.",," = [ "edit" "@+" ];

          aliases.a = [ "abandon" ];

          aliases.c  = [ "commit" ];
          aliases.ci = [ "commit" "--interactive" ];

          aliases.e = [ "edit" ];

          aliases.fetch = [ "git" "fetch" ];
          aliases.f     = [ "git" "fetch" ];

          aliases.r = [ "rebase" ];

          aliases.res         = [ "resolve" ];
          aliases.resolve-ast = [ "resolve" "--tool" "mergiraf" ];
          aliases.resa        = [ "resolve-ast" ];

          aliases.s = [ "split" ];
          aliases.sm = [ "split" "--message" ];

          aliases.sq   = [ "squash" ];
          aliases.sqf  = [ "squash" "--from" ];
          aliases.sqi  = [ "squash" "--interactive" ];
          aliases.sqm  = [ "squash" "--message" ];
          aliases.sqmi = [ "squash" "--interactive" "--message" ];

          aliases.sh = [ "show" ];

          aliases.tug = [ "bookmark" "move" "--from" "closest(@-)" "--to" "closest_pushable(@)" ];
          aliases.t   = [ "tug" ];

          aliases.push = [ "git" "push" ];
          aliases.p    = [ "git" "push" ];

          aliases.init  = [ "git" "init" "--colocate" ];
          aliases.i     = [ "git" "init" "--colocate" ];

          aliases.clone = [ "git" "clone" "--colocate" ];
          aliases.cl    = [ "git" "clone" "--colocate" ];

          aliases.d = [ "diff" ];

          aliases.l   = [ "log" ];
          aliases.la  = [ "log" "--revisions" "::" ];
          aliases.ls  = [ "log" "--summary" ];
          aliases.lsa = [ "log" "--summary" "--revisions" "::" ];
          aliases.lp  = [ "log" "--patch" ];
          aliases.lpa = [ "log" "--patch" "--revisions" "::" ];
          aliases.lg  = [ "log" "--summary" "--no-pager" "--limit=4" ];
          aliases.el  = [ "evolog" ];
          aliases.ol  = [ "op" "log" ];

          revset-aliases."closest(to)"          = "heads(::to & bookmarks())";
          revset-aliases."closest_pushable(to)" = "heads(::to & ~description(exact:\"\") & (~empty() | merges()))";

          revsets.log = "present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 8)";

          templates.draft_commit_description = /* python */ ''
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

          templates.git_push_bookmark = /* python */ ''
            "change/PlumJam-" ++ change_id.short()
          '';
        };
      };
    })
  ];
}
