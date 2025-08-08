{
  environment.variables = {
    MANPAGER = "bat";
    PAGER = "bat";
  };
  programs.bat = {
    enable = true;
    config.pager = "less --quit-if-one-screen --RAW-CONTROL-CHARS";
  };
}
