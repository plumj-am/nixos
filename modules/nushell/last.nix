{ self, ... }:
{
  flake.modules.common.nushell = self.modules.common.nushell-last;
  flake.modules.common.nushell-last =
    {
      pkgs,
      ...
    }:
    {
      hjemModule = {
        xdg.config.files."nushell/config.nu".text = # nu
          "source ${pkgs.writeText "nushell-last.nu" ''
            $env.config.hooks.display_output = {||
              tee { table --expand | print }
              # SQLite doesn't support eq comparisions
              | try { if $in != null { $env.last = $in } }
            }

            # Get output of last command
            def "_" []: nothing -> any {
              $env.last?
            }
          ''}";
      };
    };
}
