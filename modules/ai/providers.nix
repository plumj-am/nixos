{ self, ... }:
{
  flake.modules.common.default = self.modules.common.ai-providers;
  flake.modules.common.ai-providers =
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
              name = mkOption {
                type = str;
              };
              baseUrl = mkOption {
                type = str;
              };
              apiKey = mkOption {
                type = nullOr str;
                default = null;
              };
              type = mkOption {
                type = enum [ "openai-compatible" ];
              };
              auth = mkOption {
                type = str;
              };
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

      config.ai.providers.headroomVineProxy = {
        name = "vine";
        baseUrl = "http://127.0.0.1:8022/v1";
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
