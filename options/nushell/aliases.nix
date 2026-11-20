{ self, ... }:
{
  flake.modules.common.nushell-aliases = self.modules.common.nushell-aliases-options;
  flake.modules.common.nushell-aliases-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) attrsOf str;
    in
    {
      options.shellAliases = mkOption {
        type = attrsOf str;
        default = { };
        description = "Additional shell aliases to be merged with defaults";
      };
    };
}
