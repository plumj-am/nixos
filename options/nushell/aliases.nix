{ self, ... }:
{
  flake.modules.common.nushell-aliases = self.modules.common.nushell-aliases-options;
  flake.modules.common.nushell-aliases-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) attrsOf str;
    in
    {
      options.shellAliases = mkOptionOf (attrsOf str) {
        default = { };
        description = "Additional shell aliases to be merged with defaults";
      };
    };
}
