{ config, pkgs, lib, keys, ... }: let
  inherit (lib) enabled;
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
