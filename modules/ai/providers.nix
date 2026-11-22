{ self, ... }:
{
  flake.commonModules.default = self.commonModules.ai-providers;
  flake.commonModules.ai-providers =
    { lib, ... }:
    let
      inherit (lib.constants) tailnet;
    in
    {
      config.ai.providers.vineProxy = {
        name = "vine";
        baseUrl = "http://plum.${tailnet}:8023/v1";
        apiKey = "sk-vine-local"; # accepted by vine; subs live in vine env
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
