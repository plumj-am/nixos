{ pkgs, ... }:
{
  home.packages = [
    pkgs.jjui
  ];
  programs.git.difftastic.enable = true;
  programs.mergiraf.enable = true;
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "James Plummer";
        email = "jamesp2001@live.co.uk";
      };
      signing = {
        key = "58805BF7676222B4";
        backend = "gpg";
        behavior = "own";
      };
      ui = {
        editor = "nvim";
        default-command = "log --summary";
        conflict-marker-style = "snapshot";
        diff-editor = ":builtin";
        graph-style = "square";
        diff-formatter = [
          "difft"
          "--color"
          "always"
          "$left"
          "$right"
        ];
      };
      git = {
        sign-on-push = true; # sign in bulk on push
        auto-local-bookmark = true;
      };
      aliases = {
        push = [
          "git"
          "push"
        ];
        P = [
          "git"
          "push"
        ];
        fetch = [
          "git"
          "fetch"
        ];
        f = [
          "git"
          "fetch"
        ];
        init = [
          "git"
          "init"
          "--colocate"
        ];
        clone = [
          "git"
          "clone"
          "--colocate"
        ];
        d = [ "diff" ];
        ds = [ "diff --staged" ];
      };
    };
  };
}
