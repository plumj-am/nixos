{
  config.flake.modules.homeModules.bat =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;

      exe = getExe pkgs.bat;
      package = pkgs.bat;
      less = pkgs.less;
    in
    {
      environment.sessionVariables = {
        MANPAGER = "${exe} --plain";
        PAGER = "${exe} --plain";
      };

      programs.nushell.aliases = {
        cat = "${exe} --pager=${less} --quit-if-one-screen --RAW-CONTROL-CHARS";
        less = "${exe} --plain";
      };

      packages = [ package ];
    };
}
