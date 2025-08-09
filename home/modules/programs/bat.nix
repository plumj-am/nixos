{
  home.sessionVariables = {
    MANPAGER = "bat";
    PAGER = "bat";
  };
  programs.less.enable = true;
  programs.bat = {
    enable = true;
    config.pager = "less --quit-if-one-screen --RAW-CONTROL-CHARS";
  };
}
