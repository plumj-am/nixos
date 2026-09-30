{ self, ... }:
{
  flake.modules.common.ai-permissions = self.modules.common.ai-permissions-options;
  flake.modules.common.ai-permissions-options =
    { lib, ... }:
    let
      inherit (lib.options) mkEnableOption mkOptionOf;
      inherit (lib.types) listOf str;
    in
    {
      options.ai = {
        secrets = mkEnableOption "include AI secrets with this system/module";

        commands.bash.allow = mkOptionOf (listOf str) {
          default = [ ];
          description = ''
            bash command globs to allow in compatible AI tools
          '';
        };
      };
    };
}
