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

      provider = "opencode-go";

      agentModels = {
        sisyphus = "deepseek-v4-pro"; # Orchestrator - needs strong model - Claude Opus or Kimi K2.6 recommended.
        prometheus = "deepseek-v4-pro"; # Investigates bugs, runtime errors, production incidents.
        oracle = "deepseek-v4-pro"; # Architecture - needs strong model
        librarian = "deepseek-v4-flash"; # Research - use cheap, fast models.
        explore = "deepseek-v4-flash";
        multimodal-looker = "kimi-k2.6"; # Vision-capable.
        metis = "deepseek-v4-pro"; # Pre-planning consultant.
        momus = "deepseek-v4-pro"; # Plan reviewer.
        atlas = "deepseek-v4-flash"; # Task executor - carries out delegated implementation work.
        sisyphus-junior = "deepseek-v4-flash"; # Lightweight orchestrator - simpler tasks that don't need full Sisyphus.
      };

      categoryModels = {
        visual-engineering = "kimi-k2.6"; # Visual tasks.
        ultrabrain = "deepseek-v4-pro"; # Deep logical reasoning.
        deep = "deepseek-v4-pro"; # Goal-oriented autonomous problem-solving.
        artistry = "deepseek-v4-flash"; # Creative/artistic.
        quick = "deepseek-v4-flash"; # Trivial tasks.
        unspecified-low = "deepseek-v4-flash"; # Unclassified tasks, low effort.
        unspecified-high = "deepseek-v4-pro"; # Unclassified tasks, high effort.
        writing = "deepseek-v4-pro"; # Documentation, prose, technical writing.
      };
    in

    {
      hjem.extraModule = {
        packages = singleton inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.oh-my-opencode;

        xdg.config.files = {
          "opencode/oh-my-openagent.jsonc" = {
            generator = pkgs.writers.writeJSON "omo-oh-my-openagent.jsonc";
            value = {
              "$schema" =
                "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

              auto_update = false;

              agents = mapAttrs (_: model: { model = "${provider}/${model}"; }) agentModels;
              categories = mapAttrs (_: model: { model = "${provider}/${model}"; }) categoryModels;
            };
          };
        };
      };
    };
}
