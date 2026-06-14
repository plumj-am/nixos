{
  flake.modules.common.omo =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.attrsets) mapAttrs;

      provider = "commandcode";

      claude = "kimi-k2.6"; # communicators/planners
      gpt = "deepseek-v4-pro"; # deep specialists
      gemini = "qwen-3.6-plus"; # vision-capable
      fast = "deepseek-v4-flash";

      agentModels = {
        sisyphus = claude; # main orchestrator
        prometheus = claude; # strategic planner
        oracle = gpt; # architecture consultant
        librarian = fast; # docs/code search
        explore = fast; # fast codebase grep
        hephaestus = gpt; # autonomous, deep worker
        multimodal-looker = gemini; # vision/screenshots
        metis = claude; # plan gap analyzer
        momus = gpt; # reviewer
        atlas = claude; # todo orchestrator
        sisyphus-junior = claude; # lightweight orchestrator
      };

      categoryModels = {
        visual-engineering = claude; # frontend, UI, and design
        artistry = claude; # creative/artistic
        ultrabrain = claude; # maximum reasoning
        deep = claude; # deep coding, complex logic
        quick = fast; # simple, fast tasks
        unspecified-low = claude; # general complex work
        unspecified-high = fast; # general standard work
        writing = claude; # docs, text, and prose
      };
    in

    {
      ai.secrets = true;

      hjem.extraModule = {
        packages = singleton inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.oh-my-opencode;

        xdg.config.files = {
          "opencode/oh-my-openagent.jsonc" = {
            generator = pkgs.writers.writeJSON "omo-oh-my-openagent.jsonc";
            value = {
              "$schema" =
                "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

              auto_update = false;

              team_mode.enabled = true;

              agents = mapAttrs (_: model: { model = "${provider}/${model}"; }) agentModels;
              categories = mapAttrs (_: model: { model = "${provider}/${model}"; }) categoryModels;
            };
          };
        };
      };
    };
}
