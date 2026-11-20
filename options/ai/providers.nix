{ self, ... }:
{
  flake.modules.common.ai-providers = self.modules.common.ai-providers-options;
  flake.modules.common.ai-providers-options =
    { lib, ... }:
    let
      inherit (lib.attrsets) filterAttrsRecursive;
      inherit (lib.options) mkOption;
      inherit (lib.types)
        attrsOf
        enum
        nullOr
        str
        submodule
        ;
    in
    {
      options.ai.providers = mkOption {
        type =
          attrsOf
          <| submodule {
            options = {
              name = mkOption { type = str; };
              baseUrl = mkOption { type = str; };
              apiKey = mkOption {
                type = nullOr str;
                default = null;
              };
              type = mkOption { type = enum [ "openai-compatible" ]; };
              auth = mkOption { type = str; };
              discoveryType = mkOption {
                type = nullOr str;
                default = null;
              };
            };
          };
        default = { };
        apply = filterAttrsRecursive (_: value: value != null);
        # Drop optional-null defaults; consumers see only defined keys.
        description = ''
          Typed AI provider registry, shared by agent tool configs.
        '';
      };
    };
}
