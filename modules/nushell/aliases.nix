{ self, ... }:
{
  flake.modules.common.nushell = self.modules.common.nushell-aliases;
  flake.modules.common.nushell-aliases =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
    in
    {
      config.hjemModule =
        {
          osConfig,
          config,
          ...
        }:
        let
          inherit (osConfig) theme;

          # TODO: move to where they are needed
          aliases = {
            mp = "mprocs";

            todo = "ms ${config.directory}/notes/todo.md";
            notes = "ms ${config.directory}/notes";
            random = "ms ${config.directory}/notes/random.md";

            rm = "rm --recursive --verbose";
            cp = "cp --recursive --verbose --progress";
            mv = "mv --verbose";
            mk = "mkdir";

            ls = "eza";
            sl = "eza";
            ll = "eza -la";
            la = "eza -a";
            lsa = "eza -a";
            lsl = "eza -l -a";

            tree = "eza --tree --git-ignore --group-directories-first";

            oops = "nix run nixpkgs#sqlite -- ${config.xdg.config.directory}/nushell/history.sqlite3 'DELETE FROM history WHERE rowid IN (SELECT rowid FROM history ORDER BY rowid DESC LIMIT 5);'";

            less = "${getExe pkgs.bat} --plain";

            nfc = "nix flake check --log-format internal-json -v err>| rom --json";

            nu-config-reference = "nu -c 'config nu --doc | nu-highlight | bat'";

            # Frequently mistyped:
            nxi = "nix";
          };

          # `environment.shellAliases` targets POSIX shells. An entry that
          # re-invokes the command it shadows (`ls = "ls --color=tty"`) is a
          # parse error in nushell and would take the whole alias file down with
          # it, so those stay out.
          inheritableShellAliases = lib.filterAttrs (
            name: value: (lib.head (lib.splitString " " value)) != name
          ) osConfig.shellAliases;

          aliases' = aliases // inheritableShellAliases;
        in
        {
          xdg.config.files."nushell/config.nu".text =
            # nu
            ''
              source ${pkgs.writeText "nushell-aliases.nu" ''
                ${
                  # Nushell aliases are parsed once, so `cat` has to be a
                  # definition to follow the live theme (`$env.THEME_BAT` is set
                  # by nushell-prompt.nu).
                  lib.optionalString (!(aliases' ? cat)) ''
                    def --wrapped cat [...args] { ${getExe pkgs.bat} --theme ($env.THEME_BAT? | default "${theme.bat}") ...$args }
                  ''
                }
                ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: val: "alias ${name} = ${val}") aliases')}
              ''}
            '';
        };
    };
}
