{ self, ... }:
{
  flake.modules.common.default = self.modules.common.ai-models;
  flake.modules.common.ai-models =
    { lib, ... }:
    let
      inherit (lib.attrsets) filterAttrsRecursive;
      inherit (lib.lists) findFirst singleton;
      inherit (lib.options) mkOptionNullOr mkOptionOf;
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

      config.ai.defaultModels =
        let
          freeStrong = {
            model = "stealth/space-bunny-alpha";
            vision = true;
          };
          freeWeak = {
            model = null;
            vision = false;
          };

          firstOrDefault = candidates: default: findFirst (m: m != null && m != "") default candidates;
          visionOf = m: if m.vision then m.model else null;
        in
        {
          # strong -> weak -> default
          small = firstOrDefault [ freeStrong.model freeWeak.model ] "xiaomi/mimo-v2.6-flash";
          vision = firstOrDefault [ (visionOf freeStrong) (visionOf freeWeak) ] "xiaomi/mimo-v2.6-flash";
          # strong -> default
          big = firstOrDefault [ freeStrong.model ] "xiaomi/mimo-v2.6-pro";
          # weak -> default
          fallback = firstOrDefault [ freeWeak.model ] "deepseek/deepseek-v4.1-flash";
        };

      options.ai.models =
        mkOptionOf
          (
            listOf
            <| submodule {
              options = {
                id = mkOptionOf str;
                name = mkOptionOf str;
                reasoning = mkOptionOf bool;
                thinking = mkOptionOf (submodule {
                  options = {
                    minLevel = mkOptionOf thinkingLevel;
                    maxLevel = mkOptionOf thinkingLevel;
                    mode = mkOptionOf (enum [ "effort" ]);
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
            apply = map <| filterAttrsRecursive (_: value: value != null);
            description = ''
              Typed AI model registry, shared by agent tool configs.
            '';
          };

      config.ai.models = [
        {
          # high | xhigh
          id = "deepseek/deepseek-v4.1-flash";
          name = "DeepSeek V4.1 Flash";
          reasoning = true;
          thinking = {
            minLevel = "high";
            maxLevel = "xhigh";
            mode = "effort";
          };
          inputTypes = singleton "text";
          context = 1000000;
          maxOutput = 384000;
          compat = {
            supportsDeveloperRole = false;
            supportsReasoningEffort = true;
            maxTokensField = "max_tokens";
            reasoningEffortMap = {
              low = "high"; # lowest available for V4 models
              high = "high";
              xhigh = "max";
            };
            supportsToolChoice = false;
            requiresReasoningContentForToolCalls = true;
            requiresAssistantContentForToolCalls = true;
            extraBody.thinking.type = "enabled";
          };
          costPerMillion = {
            input = 0.15;
            output = 0.6;
            cacheRead = 0.003;
            cacheWrite = 0;
          };
        }
        {
          id = "xiaomi/mimo-v2.6-flash";
          name = "Mimo v2.6 Flash";
          reasoning = true;
          thinking = {
            minLevel = "minimal";
            maxLevel = "high";
            mode = "effort";
          };
          context = 1048576;
          maxOutput = 131072;
          inputTypes = [
            "text"
            "image"
          ];
          costPerMillion = {
            input = 0.14;
            output = 0.28;
            cacheRead = 0.0028;
            cacheWrite = 0;
          };
        }
        {
          id = "xiaomi/mimo-v2.6-pro";
          name = "Mimo v2.6 Pro";
          reasoning = true;
          thinking = {
            minLevel = "minimal";
            maxLevel = "high";
            mode = "effort";
          };
          context = 1048576;
          maxOutput = 131072;
          inputTypes = [
            "text"
            "image"
          ];
          costPerMillion = {
            input = 0.435;
            output = 0.87;
            cacheRead = 0.0036;
            cacheWrite = 0;
          };
        }
        {
          # minimal | low | medium | high | xhigh
          id = "meta/muse-spark-1.3-contributor";
          name = "Meta Muse Spark 1.3 Contributor";
          reasoning = true;
          thinking = {
            minLevel = "minimal";
            maxLevel = "max";
            mode = "effort";
          };
          inputTypes = [
            "text"
            "image"
          ];
          costPerMillion = {
            input = 0.1;
            output = 0.2;
            cacheRead = 0.002;
            cacheWrite = 0;
          };
          context = 1048576;
          maxOutput = 131072;
          compat = {
            supportsReasoningEffort = true;
            supportsToolChoice = false;
          };
        }
        {
          # low | medium | high
          id = "stealth/space-bunny-alpha";
          name = "Space Bunny Alpha";
          reasoning = true;
          thinking = {
            minLevel = "low";
            maxLevel = "high";
            mode = "effort";
          };
          inputTypes = [
            "text"
            "image"
          ];
          costPerMillion = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
          context = 1000000;
          maxOutput = 262144;
        }
      ];
    };
}
