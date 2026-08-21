{ self, ... }:
{
  flake.modules.common.shell-tools =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.attrsets) attrNames;
      inherit (lib.strings) toJSON;
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
          pkgs.ripgrep
          pkgs.vivid

          inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.rustle
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

        xdg.config.files."nushell/config.nu".text = "source ${
          pkgs.writeText "nix-run.nu" # nu
            ''
              def >? []: string -> string {
                if ($in | str contains "#") or ($in | str contains ":") {
                  $in
                } else if $in in ${toJSON <| attrNames self.packages.${config.nixpkgs.hostPlatform.system}} {
                  "path:${self}#" + $in
                } else {
                  "path:${inputs.nixpkgs}#" + $in
                }
              }

              def --wrapped , [program: string = "", ...rest] {
                nix run ($program | >?) -- ...$rest
              }

              def --wrapped > [...rest: string] {
                nix shell ...($rest | each { $in | >? })
              }
            ''
        }";
      };
    };
}
