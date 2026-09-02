{
  flake.modules.common.commandcode =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.trivial) flip const;
      inherit (lib.meta) getExe';
      inherit (config) theme;
      inherit (config.sops) secrets;
      inherit (config.ai.subs.commandcode) active;

      activeSub = "commandcode-auth-${toString active}";
    in
    {
      ai.secrets = true;

      shellAliases.cmd = "${getExe' pkgs.nodejs-slim "npx"} command-code@latest";

      hjem.extraModule = {
        files = {
          ".commandcode/config.json" = {
            generator = pkgs.writers.writeJSON "commandcode-config.json";
            type = "copy";
            value =
              let
                normal = "deepseek/deepseek-v4-flash";
                cheap = "meituan/LongCat-2.0:free";
              in
              {
                provider = "command-code";
                installed = true;
                theme = if theme.isDark then "dark" else "light";
                model = normal;
                firstMessageSent = true;
                tasteLearning = true;
                featureModels = flip genAttrs (const cheap) [
                  "titleGeneration"
                  "compaction"
                  "toolDescription"
                  "tasteOnboarding"
                  "tasteLearning"
                ];
              };
          };
          ".commandcode/auth.json".source = secrets."${activeSub}-json".path;
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
