{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.headroom;
  flake.modules.common.headroom =
    {
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton self.services.headroom;

      services.headroom = {
        enable = true;

        port = 8022;
        # Local Vine (both subs). Headroom compresses, then forwards
        # `/v1/chat/completions` to Vine; no `/v1` suffix here.
        openaiApiUrl = "http://127.0.0.1:8023";
      };
    };
}
