let
  jujutsuExtra =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModules = singleton {
        packages = [
          pkgs.jujutsu
          pkgs.difftastic
          pkgs.mergiraf

          pkgs.lazyjj
          pkgs.jjui
        ];
      };
    };

  jujutsuBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) theme;

      toml = pkgs.formats.toml { };
      jjConfig = {
        user.name = "PlumJam";
        user.email = "git@plumj.am";

        signing.key = "/home/jam/.ssh/id";
        signing.backend = "ssh";
        signing.behavior = "own";

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
        ui.editor = config.environment.variables.EDITOR;
        ui.graph.style = "curved";
        ui.movement.edit = true;
        ui.pager = ":builtin";

        snapshot.max-new-file-size = "10MiB";

        lazyjj.highlight-color = "#${theme.colors.base02}";

        git = {
          sign-on-push = true; # Sign in bulk on push.
          subprocess = true;
          private-commits = "description('wip:*') | description('private:*')"; # Prevent pushing WIP commits.
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

        aliases.r = [ "rebase" ];

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
          "--no-pager"
          "--limit=4"
        ];
        aliases.el = [ "evolog" ];
        aliases.ol = [
          "op"
          "log"
        ];

        revset-aliases."closest(to)" = "heads(::to & bookmarks())";
        revset-aliases."closest_pushable(to)" =
          "heads(::to & ~description(exact:\"\") & (~empty() | merges()))";

        revsets.log = "present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 8)";

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

        templates.git_push_bookmark = # python
          ''
            "patch/PlumJam-" ++ change_id.short()
          '';
      };

      # TODO: Fix sub-menu selection bg colour (press "l" on revision to view files)
      jjuiConfig = {
        preview.show_at_start = true;

        ui.colors."selected".bg = "#${theme.colors.base01}";

      };
    in
    {
      hjem.extraModules = singleton {
        xdg.config.files."jj/config.toml".source = toml.generate "jj-config.toml" jjConfig;
        xdg.config.files."jjui/config.toml".source = toml.generate "jjui-config.toml" jjuiConfig;
      };
    };
in
{
  flake.modules.nixos.jujutsu = jujutsuBase;
  flake.modules.darwin.jujutsu = jujutsuBase;

  flake.modules.nixos.jujutsu-extra = jujutsuExtra;
  flake.modules.darwin.jujutsu-extra = jujutsuExtra;
}
