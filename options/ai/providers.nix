{ self, ... }:
{
  flake.modules.common.ai-providers = self.modules.common.ai-providers-options;
  flake.modules.common.ai-providers-options =
    { lib, ... }:
    let
      inherit (lib.attrsets) filterAttrsRecursive;
      inherit (lib.options) mkOptionNullOr mkOptionOf;
      inherit (lib.types)
        attrsOf
        enum
        str
        submodule
        ;
    in
    {
      options.ai.providers =
        mkOptionOf
          (
            attrsOf
            <| submodule {
              options = {
                name = mkOptionOf str;
                baseUrl = mkOptionOf str;
                apiKey = mkOptionNullOr str;
                type = mkOptionOf (enum [ "openai-compatible" ]);
                auth = mkOptionOf str;
                discoveryType = mkOptionNullOr str;
              };
            }
          )
          {
            default = { };
            apply = filterAttrsRecursive (_: value: value != null);
            # Drop optional-null defaults; consumers see only defined keys.
            description = ''
              Typed AI provider registry, shared by agent tool configs.
            '';
          };
    };
}
