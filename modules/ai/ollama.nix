{
  flake.modules.nixos.ollama =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) filter elem;

      localModels = config.ai.models.local;
    in
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;

        port = 11434;

        syncModels = true;
        loadModels = map (m: m.id) <| filter (m: elem m.id localModels.enabledIDs) localModels.all;

        environmentVariables = {
          OLLAMA_NUM_PARALLEL = "4";
          OLLAMA_MAX_LOADED_MODELS = "2";
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_NO_CLOUD = "1";
        };
      };
    };
}
