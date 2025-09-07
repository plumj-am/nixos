{ lib, ... }:
let
	inherit (lib) enabled;
in
{
  home.sessionVariables = {
    MANPAGER = "bat";
    PAGER    = "bat";
  };
  programs.less = enabled;
  programs.bat  = enabled {
    config.pager = "less --quit-if-one-screen --RAW-CONTROL-CHARS";
  };
}
