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

            todo = "hx ${config.directory}/notes/todo.md";
            notes = "hx ${config.directory}/notes";
            random = "hx ${config.directory}/notes/random.md";

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

            cat = "${getExe pkgs.bat} --theme ${theme.bat}";
            less = "${getExe pkgs.bat} --plain";

            nfc = "nix flake check --log-format internal-json -v err>| rom --json";

            nu-config-reference = "nu -c 'config nu --doc | nu-highlight | bat'";

            # Frequently mistyped:
            nxi = "nix";
          };

          aliases' = aliases // osConfig.shellAliases;
        in
        {
          xdg.config.files."nushell/config.nu".text =
            # nu
            ''
              source ${pkgs.writeText "nushell-aliases.nu" ''
                ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: val: "alias ${name} = ${val}") aliases')}
              ''}
            '';
        };
    };
}
