{ self, ... }:
{
  flake.commonModules.ai-permissions = self.commonModules.ai-permissions-options;
  flake.commonModules.ai-permissions-options =
    { lib, ... }:
    let
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) listOf str;
    in
    {
      options.ai = {
        secrets = mkEnableOption "include AI secrets with this system/module";

        commands.bash.allow = mkOption {
          type = listOf str;
          default = [ ];
          description = ''
            bash command globs to allow in compatible AI tools
          '';
        };
      };
    };
}
