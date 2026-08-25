{ self, ... }:
{
  flake.modules.common.default = self.modules.common.shell-tools;
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
      shellAliases = {
        jq = "jaq";
        btop = "btm";
        fzf = "skim";
      };

      hjem.extraModule = {
        packages = [
          pkgs.bat
          pkgs.bottom
          pkgs.eza
          pkgs.fd
          pkgs.skim
          pkgs.jaq
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

  flake.modules.nixos.shell-tools =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrsToList;
      inherit (lib.meta) getExe;
      inherit (lib.strings) toJSON;
    in
    {
      system.activationScripts.text = "${pkgs.writers.writeNu "bat-cache.nu" # nu
        ''
          print "refreshing bat cache..."

          let users = r###'${
            config.users.users
            |> filterAttrs (_: user: user.isNormalUser)
            |> mapAttrsToList (name: _: name)
            |> toJSON
          }'### | from json

          for user in $users {
            ^${pkgs.util-linux}/bin/runuser --user $user -- ${getExe pkgs.bat} cache --build
          }
        ''
      }
      ";
    };

  flake.modules.darwin.shell-tools =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
    in
    {
      system.activationScripts.postActivation.text = "${pkgs.writers.writeNu "bat-cache.nu" /* nu */ ''
        print "refreshing bat cache..."
        ^/usr/bin/sudo --set-home --user r###'${config.system.primaryUser}'### -- ${getExe pkgs.bat} cache --build
      ''}";
    };
}
