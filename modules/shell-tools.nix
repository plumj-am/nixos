let
  shellToolsBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (config) theme;

      bat = getExe pkgs.bat;
      less = getExe pkgs.less;
      pager = "${bat} --plain --theme ${theme.bat}";
    in
    {
      hjem.extraModules = singleton {
        packages = [
          pkgs.bat
          pkgs.btop
          pkgs.eza
          pkgs.fastfetch
          pkgs.fd
          pkgs.fzf
          pkgs.jq
          pkgs.less
          pkgs.ripgrep
          pkgs.vivid
        ];

        environment.sessionVariables = {
          MANPAGER = pager;
          PAGER = pager;
          BAT_PAGER = "${less} --quit-if-one-screen --RAW-CONTROL-CHARS";
          RIPGREP_CONFIG_PATH = "%h/.config/ripgrep/ripgreprc";
        };

        xdg.config.files."ripgrep/ripgreprc".text = ''
          --line-number
          --smart-case
        '';
      };
    };

in
{
  flake.modules.nixos.shell-tools = shellToolsBase;
  flake.modules.darwin.shell-tools = shellToolsBase;
}
