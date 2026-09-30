{ self, ... }:
{
  flake.services.headroom =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOptionOf;
      inherit (lib.types) package port str;

      headroom = self.packages.${pkgs.stdenv.hostPlatform.system}.headroom;

      cfg = config.services.headroom;
    in
    {
      options.services.headroom = {
        enable = mkEnableOption "headroom compression proxy for AI agents";

        port = mkOptionOf port {
          default = 8022;
          description = "Port for the headroom proxy to listen on.";
        };

        package = mkOptionOf package {
          default = headroom;
          description = "Headroom package to run the proxy from.";
        };

        # Upstream OpenAI-compatible base for the proxy's /v1/chat/completions
        # route. The AI providers append /chat/completions, so a client base
        # of <proxy>/v1 reaches exactly this + /v1/chat/completions.
        openaiApiUrl = mkOptionOf str {
          default = "http://127.0.0.1:8023";
          description = "OpenAI-compatible upstream base URL for /v1/chat/completions.";
        };
      };

      config = mkIf cfg.enable {
        environment.systemPackages = singleton cfg.package;

        systemd.services.headroom = {
          description = "Headroom compression proxy";
          wantedBy = singleton "default.target";
          wants = singleton "network-online.target";
          after = singleton "network-online.target";
          serviceConfig = {
            ExecStart = "${getExe cfg.package} proxy --port ${toString cfg.port} --openai-api-url ${cfg.openaiApiUrl}";
            Restart = "on-failure";
            RestartSec = 5;
          };
          environment = {
            HEADROOM_BEACON = "off";
            DO_NOT_TRACK = "1";
            # Hermes file reads stay verbatim; retrieved originals must not
            # loop back through compression.
            HEADROOM_EXCLUDE_TOOLS = "read_file,headroom_retrieve";

            # Beta output shaper (only supports claude code for now tho)
            HEADROOM_ROLLOUT_CHANNEL = "beta";
            HEADROOM_OUTPUT_SHAPER = "1";
          };
        };

      };
    };
}
