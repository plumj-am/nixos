{ self, ... }:
{
  flake.commonModules.nushell-aliases = self.commonModules.nushell-aliases-options;
  flake.commonModules.nushell-aliases-options =
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
