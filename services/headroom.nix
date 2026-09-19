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
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package port str;

      headroom = self.packages.${pkgs.stdenv.hostPlatform.system}.headroom;

      cfg = config.services.headroom;
    in
    {
      options.services.headroom = {
        enable = mkEnableOption "headroom compression proxy for AI agents";

        port = mkOption {
          type = port;
          default = 8787;
          description = "Port for the headroom proxy to listen on.";
        };

        package = mkOption {
          type = package;
          default = headroom;
          description = "Headroom package to run the proxy from.";
        };

        # Upstream OpenAI-compatible base for the proxy's /v1/chat/completions
        # route. The commandcode agent providers append /chat/completions, so a
        # client base of <proxy>/v1 reaches exactly this + /v1/chat/completions.
        openaiApiUrl = mkOption {
          type = str;
          default = "https://api.commandcode.ai/provider";
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

        # Direct upstream for Hermes, which handles both subs itself.
        # OMP/opencode use the chain instance above (-> vine).
        systemd.services.headroom-direct = {
          description = "Headroom compression proxy (direct upstream, for Hermes)";
          wantedBy = singleton "default.target";
          wants = singleton "network-online.target";
          after = singleton "network-online.target";
          serviceConfig = {
            ExecStart = "${getExe cfg.package} proxy --port 8787 --openai-api-url https://api.commandcode.ai/provider";
            Restart = "on-failure";
            RestartSec = 5;
            StateDirectory = "headroom-direct";
            WorkingDirectory = "/var/lib/headroom-direct";
          };
          environment = {
            HEADROOM_BEACON = "off";
            DO_NOT_TRACK = "1";
            HEADROOM_EXCLUDE_TOOLS = "read_file,headroom_retrieve";
            HEADROOM_ROLLOUT_CHANNEL = "beta";
            HEADROOM_OUTPUT_SHAPER = "1";
          };
        };
      };
    };
}
