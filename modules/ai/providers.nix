{ self, ... }:
{
  flake.modules.common.default = self.modules.common.ai-providers;
  flake.modules.common.ai-providers =
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

      config.ai.providers.headroomVineProxy = {
        name = "vine";
        baseUrl = "http://sloe.taild29fec.ts.net:8022/v1";
        apiKey = "sk-vine-local"; # forwarded by headroom; subs live in vine env
        type = "openai-compatible";
        auth = "none";
      };

      config.ai.providers.llamaCpp = {
        name = "llama.cpp";
        baseUrl = "http://127.0.0.1:11435";
        type = "openai-compatible";
        auth = "none";
        discoveryType = "llama.cpp";
      };
    };
}
