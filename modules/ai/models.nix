{ self, ... }:
{
  flake.modules.common.default = self.modules.common.ai-models;
  flake.modules.common.ai-models =
    { lib, ... }:
    let
      inherit (lib.lists) findFirst singleton;
    in
    {
      config.ai.defaultModels =
        let
          freeStrong = {
            model = "inclusionai/ling-3.1-flash:free";
            vision = false;
          };
          freeWeak = {
            model = "poolside/laguna-s-2.1-free";
            vision = false;
          };

          firstOrDefault = candidates: default: findFirst (m: m != null && m != "") default candidates;
          visionOf = m: if m.vision then m.model else null;
        in
        {
          # strong -> weak -> default
          tiny = firstOrDefault [ freeStrong.model freeWeak.model ] "deepseek/deepseek-v4.1-flash";
          # strong -> default
          small = firstOrDefault [ freeStrong.model ] "deepseek/deepseek-v4.1-flash";
          # strong -> weak -> default
          vision = firstOrDefault [
            (visionOf freeStrong)
            (visionOf freeWeak)
          ] "xiaomi/mimo-v2.6-flash";
          # strong -> default
          big = firstOrDefault [ freeStrong.model ] "z-ai/glm-5.3-flash";
          # strong -> default
          fallback = firstOrDefault [ freeStrong.model ] "xiaomi/mimo-v2.6-flash";
          decision = "typesafe/jev";
        };

      config.ai.models = [
        {
          # high | xhigh
          id = "deepseek/deepseek-v4.1-flash";
          name = "DeepSeek V4.1 Flash";
          thinking = {
            minLevel = "high";
            maxLevel = "xhigh";
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
          thinking = {
            minLevel = "minimal";
            maxLevel = "high";
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
          thinking = {
            minLevel = "minimal";
            maxLevel = "high";
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
          thinking = {
            minLevel = "minimal";
            maxLevel = "max";
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
          id = "z-ai/glm-5.3-flash";
          name = "Z.ai GLM 5.3 Flash";
          thinking = {
            minLevel = "low";
            maxLevel = "max";
          };
          inputTypes = [
            "text"
            "image"
          ];
          costPerMillion = {
            input = 0.15;
            output = 0.5;
            cacheRead = 0.03;
            cacheWrite = 0;
          };
          context = 1000000;
          maxOutput = 262144;
        }
        {
          id = "inclusionai/ling-3.1-flash:free";
          name = "Inclusion Ling 3.1 Flash";
          free = true;
          thinking = {
            minLevel = "low";
            maxLevel = "high";
          };
          inputTypes = [
            "text"
          ];
          context = 262144;
          maxOutput = 32768;
        }
        {
          id = "poolside/laguna-s-2.1-free";
          name = "Poolside Laguna S 2.1";
          free = true;
          thinking = {
            minLevel = "low";
            maxLevel = "high";
          };
          inputTypes = [
            "text"
          ];
          context = 256000;
          maxOutput = 32768;
        }
        # decision model
        {
          id = "typesafe/jev";
          name = "Typesafe Jev";
          reasoning = false;
          thinking = null;
          inputTypes = [ "text" ];
          costPerMillion = {
            input = 0.042;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
          context = 32000;
          maxOutput = 32000; # no idea
        }
      ];
    };
}
