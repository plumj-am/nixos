{
  flake.modules.common.shell-tools =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (config) theme;

      bat = getExe pkgs.bat;
      less = getExe pkgs.less;
      pager = "${bat} --plain --theme ${theme.bat}";
    in
    {
      hjem.extraModule = {
        packages = [
          pkgs.bat
          pkgs.btop
          pkgs.eza
          pkgs.devenv
          pkgs.fastfetch
          pkgs.fd
          pkgs.fzf
          pkgs.jq
          pkgs.less
          pkgs.nnn
          pkgs.ripgrep
          pkgs.vivid
        ];

        environment.sessionVariables = {
          MANPAGER = pager;
          PAGER = pager;
          BAT_PAGER = "${less} --quit-if-one-screen --RAW-CONTROL-CHARS";
          RIPGREP_CONFIG_PATH = "%h/.config/ripgrep/ripgreprc";
          NNN_FCOLORS = "0000000000000000000000000000"; # Use terminal colours.
        };

        xdg.config.files."ripgrep/ripgreprc".text = ''
          --line-number
          --smart-case
        '';
      };
    };
}
