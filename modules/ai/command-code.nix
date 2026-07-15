{
  flake.modules.common.command-code =
    { pkgs, config, ... }:
    let
      inherit (config) theme;
      inherit (config.sops) secrets;
    in
    {
      ai.secrets = true;

      shellAliases.cmd = "nix run nixpkgs#deno -- x --allow-all --no-prompt npm:command-code";

      hjem.extraModule = {
        files = {
          ".commandcode/config.json" = {
            generator = pkgs.writers.writeJSON "commandcode-config.json";
            type = "copy";
            value = {
              provider = "command-code";
              installed = true;
              theme = if theme.isDark then "dark" else "light";
              model = "tencent/Hy3";
              firstMessageSent = true;
              featureModels = {
                # TODO: change to MiniMaxAI/MiniMax-M3 and deepseek/deepseek-v4-flash after 21/07
                titleGeneration = "tencent/Hy3";
                compaction = "tencent/Hy3";
                toolDescription = "tencent/Hy3";
                tasteOnboarding = "tencent/Hy3";
              };
            };
          };
          ".commandcode/auth.json".source = secrets."command-code-auth-json".path;
          ".commandcode/updates.json" = {
            generator = pkgs.writers.writeJSON "commandcode-updates.json";
            value = {
              autoUpdate = false;
              lastCheckedAt = 1784290857865;
              pending = null;
            };
          };
        };
      };
    };
}
