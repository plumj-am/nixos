{ self, ... }:
{
  flake.modules.common.default = self.modules.common.ai-providers;
  flake.modules.common.ai-providers = {
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
