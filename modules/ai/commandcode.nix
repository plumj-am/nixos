{
  flake.modules.common.commandcode =
    { pkgs, config, ... }:
    let
      inherit (config) theme;
      inherit (config.sops) secrets;
    in
    {
      ai.secrets = true;

      shellAliases.cmd = "nix run nixpkgs#deno -- x --allow-all --no-prompt --yes npm:command-code@latest";

      hjem.extraModule = {
        files = {
          ".commandcode/config.json" = {
            generator = pkgs.writers.writeJSON "commandcode-config.json";
            type = "copy";
            value = {
              provider = "command-code";
              installed = true;
              theme = if theme.isDark then "dark" else "light";
              model = "deepseek/deepseek-v4-flash";
              firstMessageSent = true;
              featureModels = {
                titleGeneration = "deepseek/deepseek-v4-flash";
                compaction = "deepseek/deepseek-v4-flash";
                toolDescription = "deepseek/deepseek-v4-flash";
                tasteOnboarding = "deepseek/deepseek-v4-flash";
                tasteLearning = "deepseek/deepseek-v4-flash";
              };
            };
          };
          ".commandcode/auth.json".source = secrets."commandcode-auth-json".path;
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
