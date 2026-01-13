let
  batConfig =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;

      bat = getExe pkgs.bat;
      less = getExe pkgs.less;
    in
    {
      packages = [
        pkgs.bat
        pkgs.less
      ];

      environment.sessionVariables = {
        MANPAGER = "${bat} --plain";
        PAGER = "${bat} --plain";
      };

      rum.programs.nushell.aliases = {
        cat = "${bat} --pager=${less} --quit-if-one-screen --RAW-CONTROL-CHARS";
        less = "${bat} --plain";
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

      files."ripgrep/ripgreprc".text = ''
        --line-number
        --smart-case
      '';
    };

  ezaConfig =
    { pkgs, ... }:
    {
      rum.programs.nushell.aliases = {
        ls = "eza";
        sl = "eza";
        ll = "eza -la";
        la = "eza -a";
        lsa = "eza -a";
        lsl = "eza -l -a";
      };

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
  config.flake.modules.hjem.shell-tools =
    { pkgs, lib, ... }:
    let
      bat = batConfig { inherit pkgs lib; };
      ripgrep = ripgrepConfig { inherit pkgs; };
      eza = ezaConfig { inherit pkgs; };
      other = otherConfig { inherit pkgs; };
    in
    {
      packages = bat.packages ++ ripgrep.packages ++ eza.packages ++ other.packages;

      environment.sessionVariables =
        bat.environment.sessionVariables // ripgrep.environment.sessionVariables;

      rum.programs.nushell.aliases = bat.rum.programs.nushell.aliases // eza.rum.programs.nushell.aliases;

      files = ripgrep.files;
    };
}
