{
  programs.git.difftastic.enable = true;
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
        default-command = "ls";
        diff-editor = ":builtin";
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
    };
  };
}
