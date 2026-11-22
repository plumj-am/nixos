{ self, ... }:
{
  flake.commonModules.ai-models = self.commonModules.ai-models-options;
  flake.commonModules.ai-models-options =
    { lib, ... }:
    let
      inherit (lib.attrsets) filterAttrsRecursive removeAttrs;
      inherit (lib.options) mkOption;
      inherit (lib.trivial) flip;
      inherit (lib.types)
        addCheck
        anything
        attrsOf
        bool
        enum
        ints
        listOf
        nullOr
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
      options.ai.defaultModels = mkOption {
        type = attrsOf str;
        default = { };
        description = ''
          Default models for roles and mappings.
        '';
      };

      options.ai.models = mkOption {
        type =
          listOf
          <| submodule {
            options = {
              id = mkOption { type = str; };
              name = mkOption { type = str; };
              reasoning = mkOption {
                type = bool;
                default = true;
              };
              thinking = mkOption {
                type = nullOr (submodule {
                  options = {
                    minLevel = mkOption { type = thinkingLevel; };
                    maxLevel = mkOption { type = thinkingLevel; };
                    mode = mkOption {
                      type = enum [ "effort" ];
                      default = "effort";
                    };
                  };
                });
                default = null;
              };
              inputTypes = mkOption {
                type =
                  listOf
                  <| enum [
                    "text"
                    "image"
                  ];
              };
              context = mkOption { type = ints.positive; };
              maxOutput = mkOption { type = ints.positive; };
              free = mkOption {
                type = bool;
                default = false;
                description = ''
                  Whether the model is free. If set, all costs are set to 0.
                '';
              };
              costPerMillion = mkOption {
                type = submodule {
                  options = {
                    input = mkOption { type = nonNegativeNumber; };
                    output = mkOption { type = nonNegativeNumber; };
                    cacheRead = mkOption { type = nonNegativeNumber; };
                    cacheWrite = mkOption { type = nonNegativeNumber; };
                  };
                };
              };
              compat = mkOption {
                type = nullOr (submodule {
                  options = {
                    supportsDeveloperRole = mkOption {
                      type = nullOr bool;
                      default = null;
                    };
                    supportsReasoningEffort = mkOption {
                      type = nullOr bool;
                      default = null;
                    };
                    supportsToolChoice = mkOption {
                      type = nullOr bool;
                      default = null;
                    };
                    requiresReasoningContentForToolCalls = mkOption {
                      type = nullOr bool;
                      default = null;
                    };
                    requiresAssistantContentForToolCalls = mkOption {
                      type = nullOr bool;
                      default = null;
                    };
                    maxTokensField = mkOption {
                      type = nullOr str;
                      default = null;
                    };
                    reasoningEffortMap = mkOption {
                      type = nullOr (attrsOf thinkingLevel);
                      default = null;
                    };
                    # Request body merged verbatim into every call.
                    extraBody = mkOption {
                      type = nullOr (attrsOf anything);
                      default = null;
                    };
                  };
                });
                default = null;
              };
            };
          };
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
