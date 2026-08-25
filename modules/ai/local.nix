{ lib, ... }:
let
  inherit (lib.trivial) warnIf;

  isGpu = config: config.systemInfo.gpu.exists;
  isNvidiaGpu = config: config.systemInfo.gpu.vendor == "nVidia Corporation";

  noGpuWarning =
    program: config: value:
    warnIf (
      !isGpu config
    ) "${program}: no GPU detected or configured - CPU-only inference will be slow" value;
in
{
  flake.modules.nixos.llama-cpp =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.attrsets) optionalAttrs;

      cpuMoeOffload = {
        n-gpu-layers = 99;
        cpu-moe = "on";
        n-cpu-moe = 99;
        threads = "10";
        threads-batch = "20";
      };

      ngram = {
        spec-type = "ngram-mod";
        spec-ngram-size-n = "24";
        draft-min = "12";
        draft-max = "48";
      };

      mkUnslothQwen =
        {
          name,
          ctx,
          moeOffload ? true,
          ...
        }:
        {
          hf-repo = "unsloth/${name}";
          jinja = "on";
          chat-template-kwargs = ''{"preserve_thinking": true}'';
          no-mmproj-offload = "on";
          ctx-size = ctx;

          cache-type-k = "q8_0";
          cache-type-v = "q8_0";
        }
        # WARN: Ngram can break tool calls, apparently.
        // ngram
        // optionalAttrs moeOffload cpuMoeOffload;

      # Write models preset to a file and reference it by path.
      # (The module's `settings.models-preset` expects a file path, not inline INI.)
      modelsIni = pkgs.writeText "llama-models.ini" (
        lib.generators.toINI { } {
          "*" = { };

          # tps | ctx max | ctx max local
          # 8.4 | 262144  |
          "unsloth/Qwen3.6-35B-A3B:UD-IQ3_XXS" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:UD-IQ3_XXS";
            ctx = "131072";
          };

          # tps | ctx max | ctx max local
          # 8.3 | 262144  |
          "unsloth/Qwen3.6-35B-A3B:UD-IQ3_S" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:UD-IQ3_S";
            ctx = "131072";
          };

          # tps  | ctx max | ctx max local
          # 11.3 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:UD-IQ4_XS" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:UD-IQ4_XS";
            ctx = "131072";
          };

          # tps | ctx max | ctx local max
          # 0   | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:UD-IQ4_NL_XL" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:UD-IQ4_NL_XL";
            ctx = "131072"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 25.0 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q4_K_S" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q4_K_S";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 23.3 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q4_K_XL" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q4_K_XL";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 21.0 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q5_K_S" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q5_K_S";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 14.7 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q6_K" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q6_K";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 16.4 | 262144  | 0
          "unsloth/Qwen3.6-35B-A3B:Q8_K_XL" = mkUnslothQwen {
            name = "Qwen3.6-35B-A3B-GGUF:Q8_K_XL";
            ctx = "262144"; # 262144 max - untested
          };

          # tps  | ctx max | ctx max local
          # 0    | 262144  | 0
          "unsloth/Qwen3.8-27B:UD-IQ3_XXS" = mkUnslothQwen {
            name = "Qwen3.8-27B-GGUF:UD-IQ3-XXS";
            ctx = "262144"; # 262144 max - untested
            moeOffload = false;
          };

          "ornith-ai/Ornith-1.5-35B-A3B:Q4_K_M" = {
            name = "Ornith-1.5-35B-A3B:Q4_K_M";
            hf-repo = "ornith-ai/Ornith-1.5-35B-A3B-GGUF:Q4_K_M";

            context = "156000";
            jinja = "on";
            flash-attention = "on";
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            reasoning = "on";
            batch-size = 2048;
            ubatch-size = 1024;
            temp = 0.6;
            top-p = 0.95;
            top-k = 20;
            min-p = 0.0;
            presence-penalty = 0.0;
            repeat-penalty = 1.0;
          }
          // cpuMoeOffload;

          "quimmedes/Ornith-1.5-35B-A3B-XYZ:Q3-XYZ" = {
            name = "Ornith-1.5-35B-A3B-XYZ:Q3-XYZ";
            hf-repo = "quimmedes/Ornith-1.5-35B-A3B-XYZ:Q3-XYZ";

            context = "156000";
            jinja = "on";
            flash-attention = "on";
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            reasoning = "on";
            batch-size = 2048;
            ubatch-size = 1024;
            temp = 0.6;
            top-p = 0.95;
            top-k = 20;
            min-p = 0.0;
            presence-penalty = 0.0;
            repeat-penalty = 1.0;
          }
          // cpuMoeOffload;
        }
      );
    in
    {
      unfree.allowedNames = mkIf (isNvidiaGpu config) [
        "cuda_cccl"
        "cuda_cudart"
        "cuda_nvcc"
        "libcublas"
        "cuda_nvrtc"
      ];

      services.llama-cpp = {
        enable = noGpuWarning "llama-cpp" config true;
        package = pkgs.llama-cpp.override { cudaSupport = if (isNvidiaGpu config) then true else false; };

        settings = {
          host = "127.0.0.1";
          port = 11435;

          parallel = 1;
          flash-attn = "on";
          mmap = true;

          # Pass path to generated INI file instead of inline content
          models-preset = "${modelsIni}";
        };
      };
    };

  flake.modules.nixos.ollama =
    {
      pkgs,
      config,
      ...
    }:
    {
      unfree.allowedNames = [
        "cuda_cccl"
        "cuda_cudart"
        "cuda_nvcc"
        "libcublas"
        "cuda_nvrtc"
      ];

      services.ollama = {
        enable = noGpuWarning "ollama" config true;
        package = if (isNvidiaGpu config) then pkgs.ollama-cuda else pkgs.ollama;

        port = 11434;

        syncModels = true;
        loadModels = [
          "hf.co/unsloth/Qwen3.8-27B-GGUF:UD-IQ3_XXS"
          "hf.co/ornith-ai/Ornith-1.5-35B-A3B-GGUF:Q4_K_M"
          "hf.co/quimmedes/Ornith-1.5-35B-A3B-XYZ:Q3-XYZ"
        ];

        environmentVariables = {
          OLLAMA_NUM_PARALLEL = "4";
          OLLAMA_MAX_LOADED_MODELS = "2";
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_NO_CLOUD = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
          OLLAMA_MULTIUSER_CACHE = "1";
          OLLAMA_NEW_ENGINE = "1";
          OLLAMA_CONTEXT_LENGTH = "262144";
        };
      };
    };

  flake.modules.nixos.lmstudio =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      unfree.allowedNames = singleton "lmstudio";

      hjemModule = { config, ... }: {
        packages = noGpuWarning "lmstudio" config <| singleton pkgs.lmstudio;

        files.".lmstudio/settings.json" = {
          generator = pkgs.writers.writeJSON "lmstudio-settings.json";
          type = "copy";
          value = {
            language = "en";
            downloadsFolder = "${config.directory}/.lmstudio/models";
            sidebar = {
              showButtonNames = false;
              monochromeSidebarIcons = true;
            };
            configs.expandConfigsOnClick = true;
            chat = {
              showSuggestionsOnNewChat = true;
              allowOnlyOneNewChat = true;
              alwaysShowPromptTemplate = false;
              useShiftEnterToSendMessage = false;
              useKeychordToRegenerate = true;
              unloadPreviousModelOnSelect = true;
              highlightChatMessageOnHover = true;
              doubleClickMessageToEdit = false;
              doubleClickChatCellRenames = false;
              aiNamingMode = "auto";
              autoExpandReasoningBlocks = false;
              reasoningBlocksVignette = true;
              messageGenInfoMode = "lastMessage";
              visualizeSpeculativeDecoding = false;
              chatFullWidth = false;
              neverAskForToolConfirmation = false;
              skipToolConfirmationPatterns = [ ];
              showChatUtilityMenuLabels = true;
              pinnedPlugins = [ ];
              showRoleAndInsertButtons = false;
              scrollLastMessageToTop = "scrollToTopNoLatch";
              showTokenCountInChatListings = false;
              moveDeletedItemsToTrash = false;
              sidebarSort = {
                field = "createdAt";
                direction = "desc";
              };
              showSpringboardWhenClosingAllTabsInSplit = false;
              imageInputs = {
                userMaxImageDimensionPixelsEnabled = true;
                userMaxImageDimensionPixels = 2048;
                ignoreModelPreferredMaxImageDimension = false;
              };
            };
            developer = {
              showExperimentalFeatures = true;
              experimentalLoadPresets = true;
              backendDownloadChannel = "stable";
              appUpdateChannel = "stable";
              showDebugInfoBlocksInChat = false;
              showModelDownloadOptionData = false;
              showResourceConsumptionWidget = true;
              allowDevelopmentPlugins = true;
              unloadPreviousJITModelOnLoad = true;
              jitModelTTL = {
                enabled = true;
                ttlSeconds = 60 * 60; # 1 hour
              };
              autoUpdateExtensionPacks = true;
              autoDeleteExtensionPacks = true;
              separateReasoningContentInAPI = true;
              experimentFlags = [ ];
              apiPredictionHistoryEviction = {
                type = "time";
                ttlDays = 30;
              };
              attemptedInstallLmsCliOnStartup = false;
            };
            ui = {
              missionControlFullscreen = false;
              showModelFileNameInMyModels = false;
              configureLoadParamsBeforeLoad = false;
              alwaysOpenModelLoaderFromPicker = true;
              contextDisplayMode = "percentage";
              appNavigationBarPosition = "left";
              showTabStripScrollBar = false;
              tabStripFullStripStyle = false;
              openDownloadsPaneOnStartNewModelDownload = false;
            };
            cloudInference.billingContext.type = "personal";
            configPresetInclusiveness.speculativeDecoding = false;
            toggledConfigDropdowns = [ ];
            userInterfaceComplexityLevel = 0;
            developerMode = true;
            appFirstLoad = false;
            autoLoadBundledLLM = true;
            modelLoadingGuardrails = {
              mode = "low";
              customThresholdBytes = 4 * 1024 * 1024 * 1024; # 4 GB
              alwaysAllowLoadAnyway = false;
            };
            dismissedModals = [
              "LM"
              "Link"
              "Sidebar"
              "Button"
              "Popover"
            ];
            dismissedConversationSnackbars = [ ];
            pre030ChatsMigrated = 3;
            appPostUpdateNotificationPending = false;
            promptWhenCommittingUnsavedChangesWithNewFields = false;
            enableLocalService = true;
            useLlamaCppEngineProtocolRuntime3 = true;
            cliInstalled = false;
            useHFProxy = true;
            hfSearchToken = "";
            hfDownloadToken = "";
            defaultContextLength = {
              type = "custom";
              value = 262144;
            };
            appIntroAcceptedForBuild = null;
          };
        };
      };
    };
}
