{ self, ... }:
{
  flake.modules.common.ai-models = self.modules.common.ai-models-options;
  flake.modules.common.ai-models-options =
    { lib, ... }:
    let
      inherit (lib.attrsets) filterAttrsRecursive removeAttrs;
      inherit (lib.options) mkOptionNullOr mkOptionOf;
      inherit (lib.trivial) flip;
      inherit (lib.types)
        addCheck
        anything
        attrsOf
        bool
        enum
        ints
        listOf
        number
        str
        submodule
        ;

      thinkingLevel = enum [
        "minimal"
        "low"
        "medium"
        "high"
        "xhigh"
        "max"
      ];

      nonNegativeNumber = addCheck number (value: value >= 0);
    in
    {
      options.ai.defaultModels = mkOptionOf (attrsOf str) {
        default = { };
        description = ''
          Default models for roles and mappings.
        '';
      };

      options.ai.models =
        mkOptionOf
          (
            listOf
            <| submodule {
              options = {
                id = mkOptionOf str;
                name = mkOptionOf str;
                reasoning = mkOptionOf bool {
                  default = true;
                };
                thinking = mkOptionNullOr (submodule {
                  options = {
                    minLevel = mkOptionOf thinkingLevel;
                    maxLevel = mkOptionOf thinkingLevel;
                    mode = mkOptionOf (enum [ "effort" ]) {
                      default = "effort";
                    };
                  };
                });
                inputTypes = mkOptionOf (
                  listOf
                  <| enum [
                    "text"
                    "image"
                  ]
                );
                context = mkOptionOf ints.positive;
                maxOutput = mkOptionOf ints.positive;
                free = mkOptionOf bool {
                  default = false;
                  description = ''
                    Whether the model is free. If set, all costs are set to 0.
                  '';
                };
                costPerMillion = mkOptionOf (submodule {
                  options = {
                    input = mkOptionOf nonNegativeNumber;
                    output = mkOptionOf nonNegativeNumber;
                    cacheRead = mkOptionOf nonNegativeNumber;
                    cacheWrite = mkOptionOf nonNegativeNumber;
                  };
                });
                compat = mkOptionNullOr (submodule {
                  options = {
                    supportsDeveloperRole = mkOptionNullOr bool;
                    supportsReasoningEffort = mkOptionNullOr bool;
                    supportsToolChoice = mkOptionNullOr bool;
                    requiresReasoningContentForToolCalls = mkOptionNullOr bool;
                    requiresAssistantContentForToolCalls = mkOptionNullOr bool;
                    maxTokensField = mkOptionNullOr str;
                    reasoningEffortMap = mkOptionNullOr (attrsOf thinkingLevel);
                    # Request body merged verbatim into every call.
                    extraBody = mkOptionNullOr (attrsOf anything);
                  };
                });
              };
            }
          )
          {
            default = [ ];
            # Drop optional-null defaults; consumers see only defined keys.
            # Free models report zero cost regardless of declared numbers.
            apply = map (
              model:
              let
                cleaned = model |> filterAttrsRecursive (_: value: value != null) |> (flip removeAttrs [ "free" ]);
              in
              if model.free then
                cleaned
                // {
                  costPerMillion = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
              else
                cleaned
            );
            description = ''
              Typed AI model registry, shared by agent tool configs.
            '';
          };
    };
}
