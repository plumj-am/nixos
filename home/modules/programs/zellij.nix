{ lib, ... }:
let
  isDark = builtins.getEnv "DARK_MODE" == "1";
in
{
  programs.zellij = {
    enable = true;
    settings = {
      theme = if isDark then "gruvbox-dark" else "gruvbox-light";
      default_shell = "nu";
      pane_frames = false;
      simplified_ui = true;
      default_layout = "compact";
      session_serialization = false;
      attach_to_session = true;
      show_startup_tips = false;
    };
  };
}
