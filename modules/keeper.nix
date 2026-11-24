{
  flake.nixosModules.keeper =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrs' nameValuePair;
      inherit (lib.lists) findFirst singleton;
      inherit (lib.modules) merge;
      inherit (config.networking) domain;

      fqdn = "grove-keeper.${domain}";

      port = 8026;

      # The agent runs as `keeper` with HOME inside the state directory, so it cannot see
      # the interactive user's `~/.omp`. Turns use one model, so the catalog carries only
      # the default small model from the vine provider.
      provider = config.ai.providers.vineProxy;
      modelId = config.ai.defaultModels.small;
      model = findFirst (entry: entry.id == modelId) null config.ai.models;

      modelAttrRenames = {
        inputTypes = "input";
        context = "contextWindow";
        maxOutput = "maxTokens";
        costPerMillion = "cost";
      };

      keeperModels = pkgs.writers.writeYAML "keeper-agent-models.yml" {
        providers.${provider.name} = {
          inherit (provider) baseUrl;
        }
        // lib.optionalAttrs (provider ? apiKey) {
          inherit (provider) apiKey;
        }
        // {
          api = "openai-completions";
          models =
            singleton <| mapAttrs' (name: value: nameValuePair (modelAttrRenames.${name} or name) value) model;
        };
      };
    in
    {
      imports = singleton inputs.grove.nixosModules.keeper;

      assertions = singleton {
        assertion = model != null;
        message = "keeper: ai.defaultModels.small (${modelId}) is missing from ai.models";
      };

      sops.secrets."keeper/environment" = {
        sopsFile = ../secrets/services/keeper.yaml;
        owner = "keeper";
        group = "keeper";
        mode = "0600";
        restartUnits = singleton "keeper.service";
      };

      services.keeper = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.keeper;
        state_dir = "/var/lib/keeper";
        environment_file = config.sops.secrets."keeper/environment".path;
        open_firewall = false;

        cpuWeight = null;
        ioWeight = null;
        nice = null;
        cpuAffinity = null;

        omp.package = inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.omp;

        agent.packages = with pkgs; [
          bash
          coreutils
          gitMinimal
          gnused
          jujutsu
          nix
        ];

        config = {
          listen = "127.0.0.1:${toString port}";
          log_level = "info";

          repos = singleton "grove-systems/grove";
          bot_login = "grove-keeper";

          # PAT mode uses KEEPER_GITHUB_TOKEN from the environment file.
          github_app_id = null;
          github_private_key_path = null;
          github_installation_id = null;
          github_api_url = "https://api.github.com";

          git_author_name = "Grove Keeper";
          git_author_email = "grove-keeper@plumj.am";

          worker_concurrency = 2;
          task_timeout_seconds = 3600;
          question_autoclose_hours = 4;
          index_sync_seconds = 900;

          release_sentinel_enabled = false;
          release_commit_prefix = "release: bump version to ";
          release_max_rounds = 5;
          release_model = null;
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/keeper/home 0750 keeper keeper -"
        "d /var/lib/keeper/home/.omp 0700 keeper keeper -"
        "d /var/lib/keeper/home/.omp/agent 0700 keeper keeper -"
        "L+ /var/lib/keeper/home/.omp/agent/models.yml - keeper keeper - ${keeperModels}"
      ];

      services.ferronVhosts.${fqdn} = merge config.services.ferron.sslTemplate {
        proxy = "http://127.0.0.1:${toString port}";

        config = # kdl
          ''
            ${config.services.ferron.headers}
          '';
      };
    };
}
