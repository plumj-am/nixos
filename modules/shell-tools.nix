let
  batConfig =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;

      bat = getExe pkgs.bat;
      less = getExe pkgs.less;

      pager = "${bat} --plain";
    in
    {
      packages = [
        pkgs.bat
        pkgs.less
      ];

      environment.sessionVariables = {
        BAT_THEME_LIGHT = "gruvbox-light";
        BAT_THEME_DARK = "gruvbox-dark";
        MANPAGER = pager;
        PAGER = pager;
        BAT_PAGER = "${less} --quit-if-one-screen --RAW-CONTROL-CHARS";
      };
    };

  ripgrepConfig =
    { pkgs, ... }:
    {
      packages = [
        pkgs.ripgrep
      ];

      environment.sessionVariables = {
        RIPGREP_CONFIG_PATH = "/home/jam/.config/ripgrep/ripgreprc";
      };

      xdg.config.files."ripgrep/ripgreprc".text = ''
        --line-number
        --smart-case
      '';
    };

  ezaConfig =
    { pkgs, ... }:
    {
      packages = [
        pkgs.eza
      ];
    };

  otherConfig =
    { pkgs, ... }:
    {
      packages = [
        pkgs.btop
        pkgs.fastfetch
        pkgs.fd
        pkgs.fzf
        pkgs.jq
        pkgs.nix-index
        pkgs.vivid
      ];
    };
in
{
  flake.modules.hjem.shell-tools =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) flatten;

      bat = batConfig { inherit pkgs lib; };
      ripgrep = ripgrepConfig { inherit pkgs; };
      eza = ezaConfig { inherit pkgs; };
      other = otherConfig { inherit pkgs; };
    in
    {
      packages =
        [
          bat.packages
          ripgrep.packages
          eza.packages
          other.packages
        ]
        |> flatten;

      environment.sessionVariables =
        bat.environment.sessionVariables // ripgrep.environment.sessionVariables;

      xdg.config.files = ripgrep.xdg.config.files;
    };
}
