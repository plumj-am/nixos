{ self, ... }:
let
  oneshotServiceConfig = {
    Type = "oneshot";
    User = "hermes";
    Group = "hermes";
    RemainAfterExit = true;
  };

  mkHermesAgent =
    name:
    {
      inputs,
      pkgs,
      lib,
      config,
      mainModel ? config.ai.defaultModels.small,
      fallbackModel ? config.ai.defaultModels.fallback,
      smallModel ? config.ai.defaultModels.small,
      visionModel ? config.ai.defaultModels.vision,
      personality ? "concise",
      npmSkills ? config.ai.skills.npmInstalled,
      ghSkills ? config.ai.skills.ghInstalled,
      localSkills ? config.ai.skills.localInstalled,
      withInstagram ? false,
      withKiwi ? false,
      withLinear ? false,
      withMealie ? false,
      withX ? false,
      gitUsername ? "",
      gitEmail ? "",
      jjStackUsername ? "",
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs mapAttrs optionalAttrs;
      inherit (lib.lists)
        optional
        singleton
        ;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkForce mkIf;
      inherit (lib.strings) concatMapStringsSep optionalString;
      inherit (lib.trivial) const flip;
      inherit (config.helpers) rustic;
      inherit (config.sops) secrets;

      graftctl = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.graft-graftctl;
      jujutsu = inputs.jujutsu.packages.${pkgs.stdenv.hostPlatform.system}.jujutsu;
      jjStack = self.packages.${pkgs.stdenv.hostPlatform.system}.jj-stack;

      vineProvider = config.ai.providers.headroomVineProxy;
      provider = vineProvider.name;

      cfg = config.services.hermes-agent;
      package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;

      needsGitConfig = gitUsername != "" && gitEmail != "" && jjStackUsername != "";
      needsSkills = npmSkills != [ ] || ghSkills != [ ] || localSkills != [ ];

      # `skills add`/`gh skill install` list skills instead of installing when
      # no skill is named, so an empty list means "every skill in the repo".
      # Keep the star quoted: nushell glob-expands a bare `*`.
      npmSkillFlags =
        entry:
        if entry.skills == [ ] then
          "--skill '*'"
        else
          concatMapStringsSep " " (skill: "--skill ${skill}") entry.skills;

      ghSkillFlags =
        entry:
        if entry.skills == [ ] then "--all" else concatMapStringsSep " " (skill: "${skill}") entry.skills;

      # The flake's `default` package is `full`, which already carries these
      # portable extras. `.override` REPLACES extraDependencyGroups instead of
      # appending, so the list is restated here — keep it in step with upstream
      # nix/packages.nix.
      extraDependencyGroups = [
        "anthropic"
        "azure-identity"
        "bedrock"
        "daytona"
        "dingtalk"
        "edge-tts"
        "exa"
        "fal"
        "feishu"
        "firecrawl"
        "honcho"
        "messaging"
        "modal"
        "parallel-web"
        "tts-premium"
        "vercel"
        "voice"
      ]
      ++ optional pkgs.stdenv.isLinux "matrix";

      # The `wake` dependency group cannot resolve on Nix, because openWakeWord
      # declares `tflite-runtime` on Linux and that has no cp312 wheel, so uv2nix
      # fails to evaluate the whole group. sherpa-onnx is the other free, local,
      # any-phrase engine in that group, so its packages are supplied as
      # `extraPythonPackages` instead.
      #
      # `lazy_deps.ensure` refuses to install anything on a managed (Nix) build
      # unless every pin in LAZY_DEPS is already satisfied, so these must be the
      # pinned versions (sherpa-onnx==1.13.4, sentencepiece==0.2.2) and carry
      # real dist-info. nixpkgs ships older or unpackaged versions, so the
      # upstream manylinux wheels are unpacked directly.
      #
      # pypinyin is undeclared upstream: sherpa_onnx.utils.text2token imports it
      # even for an English phrase.
      wakeWheels = [
        (pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/cc/b1/8dfe5d1d72c92ea1c95db999a95b61bfbb9769f1c569f06e572eda095c52/sherpa_onnx-1.13.4-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
          hash = "sha256-XwFY81E9Otqx67oMJvDIFeU7oTuWhG2S7wla4l1kiGA=";
        })
        (pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/b6/2d/37e3da037318a70066ded0d51bc2a7f35491ae6338dd993d5eb1503fc3b5/sentencepiece-0.2.2-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
          hash = "sha256-yKFosEC8YWgSk/ealJtdkRyOJQhvQmAoW42Xq18Rldo=";
        })
        (pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/b9/7b/4cabc76fcc21c3c7d5c671d8783984d30ac9d3bb387c4ba784fca3cdfa3a/pypinyin-0.55.0-py2.py3-none-any.whl";
          hash = "sha256-1TseitLNuBX7LLYE7TEjNy9aKMb0R1cSRKyjb8YqKG8=";
        })
      ];

      # sherpa's extension links `libonnxruntime.so` against the `VERS_1.27.0`
      # symbol node, which only the copy the agent venv pins exports. Referencing
      # the venv derivation keeps it an input so it reaches the build machine,
      # and keeps the ABI locked to whatever the agent runs.
      onnxruntimeCapi = "${package.passthru.hermesVenv}/lib/python3.12/site-packages/onnxruntime/capi";

      wakePythonPackages = pkgs.stdenv.mkDerivation {
        pname = "hermes-wake-python";
        version = "1.0.0";

        nativeBuildInputs = [
          pkgs.unzip
          pkgs.autoPatchelfHook
          pkgs.patchelf
        ];

        # The wheels link libstdc++/libgomp/libz, which are not on the NixOS
        # loader path, so autoPatchelfHook rewrites the RPATHs from these.
        buildInputs = [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
          pkgs.libgcc.lib
        ];

        # onnxruntime is wired up in postFixup: the extension wants the
        # unversioned soname, which no store path provides under that name.
        autoPatchelfIgnoreMissingDeps = singleton "libonnxruntime.so";

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/${pkgs.python312.sitePackages}"
          for wheel in ${concatMapStringsSep " " toString wakeWheels}; do
            ${pkgs.unzip}/bin/unzip -q -o "$wheel" -d "$out/${pkgs.python312.sitePackages}"
          done
          runHook postInstall
        '';

        postFixup = ''
          mkdir -p "$out/lib"
          ort=$(echo ${onnxruntimeCapi}/libonnxruntime.so.1.*)
          ln -sf "$ort" "$out/lib/libonnxruntime.so"
          ${pkgs.patchelf}/bin/patchelf \
            --add-rpath "$out/lib:${onnxruntimeCapi}" \
            $out/${pkgs.python312.sitePackages}/sherpa_onnx/lib/_sherpa_onnx*.so
        '';

        # The flake builds PYTHONPATH with `requiredPythonModules`, which keeps
        # only derivations carrying `pythonModule`; without this the extra would
        # be dropped. An empty requiredPythonModules keeps the extras closure
        # empty, so the flake's collision check sees only these three packages
        # (none of which the sealed venv holds) and numpy resolves to the venv's.
        passthru = {
          pythonModule = pkgs.python312;
          requiredPythonModules = [ ];
        };
      };

      # rtk's Hermes plugin, taken from the same release as the `rtk` binary so the
      # two cannot drift. `extraPlugins` symlinks it into the plugins directory, and
      # `settings.plugins.enabled` opts in — Hermes plugins are opt-in by default.
      rtkHermesPlugin = pkgs.runCommand "rtk-rewrite" { } ''
        mkdir -p $out
        cp -r ${pkgs.rtk.src}/hooks/hermes/rtk-rewrite/. $out/
      '';
    in
    {
      imports = [
        inputs.hermes-agent.nixosModules.default
        self.modules.common.headroom
        self.modules.common.vine
      ];

      sops.secrets = {
        "hermes-shared-env" = {
          sopsFile = ../../secrets/services/hermes.yaml;
          owner = "hermes";
          group = "hermes";
          mode = "0400";
          restartUnits = singleton "hermes-agent.service";
        };
        "hermes-${name}-env" = {
          sopsFile = ../../secrets/services/hermes.yaml;
          owner = "hermes";
          group = "hermes";
          mode = "0400";
          restartUnits = singleton "hermes-agent.service";
        };
      }
      // optionalAttrs needsGitConfig {
        "hermes-${name}-github-token" = {
          sopsFile = ../../secrets/services/hermes.yaml;
          owner = "hermes";
          group = "hermes";
          mode = "0400";
          restartUnits = singleton "hermes-git-config.service";
        };
      };

      services.rustic.backups."hermes-${name}" = rustic.mkBackup "hermes-${name}" {
        paths = singleton cfg.stateDir;
        exclude = [
          "${cfg.workingDirectory}/*/target"
          "${cfg.workingDirectory}/*/node_modules"
          "${cfg.workingDirectory}/*/result"
          "${cfg.stateDir}/.cargo"
          "${cfg.stateDir}/.cache"
          "${cfg.stateDir}/.config"
          "${cfg.stateDir}/.hermes/bin"
        ];

        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      services.hermes-agent = {
        enable = true;
        inherit package;
        inherit extraDependencyGroups;

        extraPythonPackages = singleton wakePythonPackages;

        backend = {
          host = "0.0.0.0";
          port = 8020;
          mode = "dashboard"; # run the dashboard too
        };

        container.enable = false; # run natively

        user = "hermes";
        group = "hermes";
        createUser = true;
        stateDir = "/var/lib/hermes";
        workingDirectory = "${cfg.stateDir}/home";

        # Declarative config.
        configFile = null;
        settings = {
          database.journal_mode = "wal";

          model = {
            inherit provider;
            default = mainModel;
          };
          fallback_providers = singleton {
            inherit provider;
            model = fallbackModel;
          };

          providers.${provider} = {
            base_url = vineProvider.baseUrl;
            api_mode = "chat_completions";
            key_env = "VINE_API_KEY";
          };
          auxiliary =
            mapAttrs (_: v: v // { inherit provider; })
            <|
              flip genAttrs
                (const {
                  model = mainModel;
                  reasoning_effort = "xhigh";
                  fallback_chain = singleton {
                    inherit provider;
                    model = fallbackModel;
                  };
                })
                [
                  "review"
                  "triage_specifier"
                ]
              //
                flip genAttrs
                  (const {
                    model = smallModel;
                    reasoning_effort = "medium";
                    fallback_chain = singleton {
                      inherit provider;
                      model = fallbackModel;
                    };
                  })
                  [
                    "approval"
                    "compression"
                    "curator"
                    "goal_judge"
                    "kanban_decomposer"
                    "mcp"
                    "profile_describer"
                    "skills_hub"
                    "title_generation"
                    "web_extract"
                  ]
              //
                flip genAttrs
                  (const {
                    model = visionModel;
                    fallback_chain = singleton {
                      inherit provider;
                      model = "Qwen/Qwen3.8-Flash";
                    };
                  })
                  [
                    "vision"
                  ];

          terminal = {
            backend = "local";
            # cwd = ""; controlled by `workingDirectory` above - do not set here
            timeout = 180;
            home_mode = "auto";
            lifetime_seconds = 300;
          };

          browser = {
            cloud_provider = "browser-use";
            inactivity_timeout = 120;
          };
          web.backend = "nous"; # free perplexity:

          command_allowlist = config.ai.commands.bash.allow;

          tool_loop_guardrails = {
            warnings_enabled = true;
            hard_stop_enabled = false;
            warn_after = {
              exact_failure = 2;
              same_tool_failure = 3;
              idempotent_no_progress = 2;
            };
            hard_stop_after = {
              exact_failure = 5;
              same_tool_failure = 8;
              idempotent_no_progress = 5;
            };
          };

          compression = {
            enabled = true;
            progress_notices = false;
            model_thresholds =
              flip genAttrs (const 0.25) # ~250k
                [
                  "deepseek-v4.1-flash"
                  "muse-spark-1.3"
                  "mimo-v2.6"
                  "laguna-s-2.1"
                  "longcat-2.0"
                  "Qwen3.8"
                ];
            idle_compact_after_seconds = 0; # >0 = compact after N s idle
            proactive_prune_tokens = 48000; # >0 = token trigger for tool-result prune
          };

          platforms = {
            webhook = {
              enabled = true;
            };

            telegram.extra = {
              status_indicator = true;
              status_online = "🟢 Online";
              status_offline = "🔴 Offline";
            };
          };

          memory = {
            memory_enabled = true;
            user_profile_enabled = true;
          };

          memory.provider = "holographic";
          plugins.hermes-memory-store.auto_extract = true;

          plugins = {
            enabled = [
              "browser-firecrawl"
              "discord-platform"
              "disk-cleanup"
              # "email-platform"
              "homeassistant-platform"
              # "matrix-platform"
              "rtk-rewrite"
              "telegram-platform"
              "web-ddgs"
              "web-exa"
              # "whatsapp-platform"
              # "spotify"
            ];
          };

          # for messaging platforms
          session_reset = {
            mode = "none"; # none | idle | daily | both
            idle_minutes = 1440;
            at_hour = 4;
          };

          group_sessions_per_user = true;

          streaming.enabled = false; # Gateway streaming

          skills = {
            creation_nudge_interval = 15; # remind to save skills every N iterations
            external_dirs = singleton "~/.agents/skills"; # read-only
          };

          agent = {
            max_turns = 500;
            verbose = false;
            reasoning_effort = "high"; # max | xhigh | high | medium | low | minimal | none
            reasoning_overrides = { }; # per-model: { "claude-opus-4.6" = "high"; }
            api_max_retries = 10;
          };

          kanban = {
            auto_subscribe_on_create = true;
            dispatch_in_gateway = true;
            review_dispatch = true;
            dispatch_interval_seconds = 120;
            failure_limit = 3;
            max_in_progress = 1;
            auto_decompose = true;
            auto_decompose_per_tick = 3;
            reconcile_orphans = true;
            done_sub_retention_days = 90;
          };

          toolsets = [
            "browser"
            "clarify"
            # "code_execution" always spams for permissions to run useless python
            "coding"
            "cronjob"
            "debugging"
            "delegation"
            "discord"
            "file"
            "homeassistant"
            "computer_use"
            "context_engine"
            "image_gen"
            "video_gen"
            "kanban"
            "memory"
            "desktop_ui"
            "project"
            "safe"
            "search"
            "session_search"
            "skills"
            "spotify"
            "terminal"
            "todo"
            "tts"
            "vision"
            "video"
          ];

          tts = {
            provider = "edge"; # free, no key
            edge = {
              voice = "en-US-AriaNeural";
              speed = 1.2;
            };
          };
          stt = {
            enabled = true;
            language = ""; # auto-detect or for english: "en"
            local.model = "base"; # tiny | base | small | medium | large-v3 | turbo
          };
          voice.auto_tts = false;

          # "Hey hermes". This backend is headless: the desktop captures the mic
          # and streams PCM over the authenticated socket (wake.feed), and the
          # detection itself runs here on the sherpa-onnx KWS engine.
          wake_word = {
            enabled = true;
            provider = "sherpa";
            phrase = "jarvis";

            start_new_session = false;
            capture = "client";
            sensitivity = 0.5;
          };

          code_execution = {
            timeout = 300;
            max_tool_calls = 50;
          };

          delegation = {
            reasoning_effort = "medium";
            max_iterations = 50;
          };

          display = {
            skin = "mono";
            inherit personality;
            compact = false;
            tool_progress = "all"; # off | new | all | verbose | log
            cleanup_progress = false;
            interim_assistant_messages = true;
            long_running_notifications = true;
            memory_notifications = "verbose";
            busy_ack_detail = true;
            busy_input_mode = "interrupt"; # interrupt | queue | steer
            background_process_notifications = "all"; # off | result | error | all
            bell_on_complete = false;
            show_reasoning = false;
            streaming = true;

            pet = {
              enabled = true;
              slug = "boxcat";
            };
          };

          discord = {
            require_mention = true;
            auto_thread = true; # on mentions
            allow_mentions = {
              roles = true;
              users = true;
              replied_user = true;
            };
            missed_message_backfill = {
              enabled = true;
              channels = singleton "*";
            };
          };

          telemetry.shared_metrics.enabled = false;
        };

        environmentFiles = [
          secrets."hermes-shared-env".path
          secrets."hermes-${name}-env".path
        ];

        # Non-secret env vars.
        environment.VINE_API_KEY = vineProvider.apiKey;

        authFile = null;
        authFileForceOverwrite = false;

        documents = { };

        mcpServers = {
          # don't use built-in server - only supports oauth which fails remotely
          linear =
            mkForce
            <| mkIf withLinear {
              url = "https://mcp.linear.app/mcp";
              headers = {
                Authorization = "Bearer \${LINEAR_API_KEY}";
              };
            };

          mealie = mkIf withMealie {
            command = "${getExe pkgs.uv}";
            args = [
              "tool"
              "run"
              "git+https://github.com/rldiao/mealie-mcp-server"
            ];
            env = {
              MEALIE_BASE_URL = "https://mealie.plumj.am";
              MEALIE_API_KEY = "\${MEALIE_API_KEY}";
            };
          };

          instagram = mkIf withInstagram {
            command = "${getExe pkgs.uv}";
            # Upstream declares only `mcp>=1.2.0` and still imports
            # `mcp.server.fastmcp`, which mcp 2.x deleted (renamed to
            # `mcp.server.mcpserver`), so resolution must stay below 2.0 or the
            # server dies on import. Drop the `--with` once upstream migrates.
            args = [
              "tool"
              "run"
              "--from"
              "git+https://github.com/William-Gao/instagram-mcp"
              "--with"
              "mcp<2"
              "python"
              "-m"
              "instagram_mcp"
            ];
            env = {
              INSTAGRAM_ACCESS_TOKEN = "\${INSTAGRAM_ACCESS_TOKEN}";
              INSTAGRAM_FB_ACCESS_TOKEN = "\${INSTAGRAM_FB_ACCESS_TOKEN}";
              INSTAGRAM_FB_IG_USER_ID = "\${INSTAGRAM_FB_IG_USER_ID}";
            };
          };

          "x.md" = mkIf withX {
            url = "https://x.pcstyle.dev/mcp";
            auth = null;
          };

          gh_grep = {
            url = "https://mcp.grep.app";
            auth = null;
          };

          context7 = {
            url = "https://mcp.context7.com/mcp";
            headers = {
              CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
            };
          };

          deepwiki = {
            url = "https://mcp.deepwiki.com/mcp";
            auth = null;
          };

          kiwi = mkIf withKiwi {
            url = "https://mcp.kiwi.com";
            auth = null;
          };

          wolfram = {
            url = "https://agenttools.wolfram.com/mcp";
            auth = null;
          };
        };

        extraArgs = [ ]; # extra args for `hermes gateway`
        extraPackages = [
          package

          # pkgs.chromium # TODO: long build, do later
          # `ld`, so ctypes.util.find_library can resolve libopus for the
          # Discord voice channels.
          pkgs.binutils
          pkgs.curl
          pkgs.dig
          pkgs.ffmpeg
          pkgs.file
          pkgs.gh
          pkgs.gitMinimal
          graftctl
          jjStack
          pkgs.jq
          jujutsu
          pkgs.nmap
          pkgs.nodejs
          pkgs.nushell
          pkgs.python3
          pkgs.ripgrep
          pkgs.rtk
          pkgs.unzip
          pkgs.whois
          pkgs.yq-go
          pkgs.zip
        ];
        extraPlugins = singleton rtkHermesPlugin;
      };

      users.users.hermes.linger = true;

      systemd.services.hermes-agent = {
        # Single place for pull and order: helpers run only when the
        # agent starts, and complete before it.
        after =
          optional needsSkills "hermes-install-skills.service"
          ++ optional needsGitConfig "hermes-git-config.service";
        wants =
          optional needsSkills "hermes-install-skills.service"
          ++ optional needsGitConfig "hermes-git-config.service";
        restartTriggers = singleton "${cfg.stateDir}/.hermes/.env";

        # libopus for the Discord voice channels: discord.py resolves it with
        # ctypes.util.find_library, and glibc reads LD_LIBRARY_PATH only at
        # process start — a `.env` entry is too late for dlopen.
        environment.LD_LIBRARY_PATH = lib.makeLibraryPath <| singleton pkgs.libopus;

        # NOTE: No `MemoryDenyWriteExecute` - breaks CPython JIT-ish paths
        serviceConfig = {
          UnsetEnvironment = singleton "INVOCATION_ID"; # HACK: run cron in-process - loads of workarounds needed otherwise
          UMask = "0007";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = mkForce true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          ProtectHostname = true;
          ProtectClock = true;
          LockPersonality = true;
          RestrictRealtime = true;
          CapabilityBoundingSet = [ ];
          SystemCallArchitectures = "native";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          ReadWritePaths = [
            cfg.stateDir
            cfg.workingDirectory
          ];
        };
      };

      systemd.services.hermes-install-skills = mkIf needsSkills {
        description = "Install skills for Hermes";
        serviceConfig = oneshotServiceConfig;
        environment = {
          HOME = cfg.stateDir;
          PYTHON = getExe pkgs.python3;
        };
        path = mkIf (ghSkills != [ ] || npmSkills != [ ]) [
          pkgs.bash
          pkgs.gcc
          pkgs.gitMinimal
          pkgs.gnumake
          pkgs.nodejs
          pkgs.node-gyp
        ];
        script = "${pkgs.writers.writeNu "hermes-install-skills.nu" # nu
          ''
            ${optionalString (npmSkills != [ ]) ''
              print "installing hermes skills from npm..."
              ${concatMapStringsSep "\n" (entry: ''
                print "adding skills from ${entry.repo}"
                (${getExe pkgs.skills} add ${entry.repo}
                  ${npmSkillFlags entry}
                  --yes
                  --agent universal
                  --global)
              '') npmSkills}
            ''}

            ${optionalString (ghSkills != [ ]) ''
              print "installing hermes skills from gh..."
              ${concatMapStringsSep "\n" (entry: ''
                print "adding skills from ${entry.repo}"
                (${getExe pkgs.gh} skill install ${entry.repo}
                  ${ghSkillFlags entry}
                  --agent universal
                  --scope user
                  --force)
              '') ghSkills}
            ''}

            ${optionalString (localSkills != [ ]) ''
              print "installing hermes local skills..."
              ${concatMapStringsSep "\n" (skill: ''
                print "installing local skill ${skill.name}"
                let skills_dir = ($env.HOME | path join ".agents" "skills" "${skill.name}")
                %mkdir $skills_dir
                open --raw ${pkgs.writeText "hermes-local-skill-${skill.name}-SKILL.md" skill.skillmd} | save --force ($skills_dir | path join "SKILL.md")
              '') localSkills}
            ''}
          ''
        }";
      };

      # Git config for the hermes user.
      systemd.services.hermes-git-config = mkIf needsGitConfig {
        description = "Write git config for hermes user";
        after = singleton "sops-install-secrets.service";
        environment.HOME = cfg.stateDir;
        serviceConfig = oneshotServiceConfig;
        script = ''
          rm --force ${cfg.stateDir}/.config/gh/hosts.yml
          ${getExe pkgs.gh} auth login --with-token --git-protocol https < ${
            secrets."hermes-${name}-github-token".path
          }

          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig user.name "${gitUsername}"
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig user.email "${gitEmail}"
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig init.defaultBranch master
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig pull.rebase true
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig rerere.enabled true
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig push.autoSetupRemote true
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig credential.helper "!gh auth git-credential"
        '';
      };
    };

  mkRepoCloneService = pkgs: cfg: owner: repo: {
    systemd.services."hermes-clone-${owner}-${repo}" = {
      description = "Clone the ${owner}/${repo} repo from GitHub";
      wantedBy = [ "hermes-agent.service" ];
      serviceConfig = oneshotServiceConfig;
      environment.HOME = cfg.stateDir;
      path = [ pkgs.gitMinimal ];
      script = "${pkgs.writers.writeNu "hermes-clone-${owner}-${repo}.nu" # nu
        ''
          let owner = "${owner}"
          let repo = "${repo}"
          let full = $"($owner)/($repo)"
          let clone_dir = ("${cfg.workingDirectory}" | path join $repo)

          if not ($clone_dir | path join ".git" | path exists) {
            print $"cloning ($full) to ($clone_dir)..."
            try {
              ${pkgs.gh}/bin/gh repo clone $full $clone_dir
            } catch {|e|
              error make $"repo clone failed in ($clone_dir): ($e)"
            }
          }
        ''
      }";
    };
  };
in
{
  flake.modules.nixos.hermes-grove =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.hermes-agent;
    in
    {
      imports = [
        (mkHermesAgent "grove" {
          inherit
            config
            inputs
            lib
            pkgs
            ;
          gitUsername = "Grove Keeper";
          gitEmail = "keeper-bot@plumj.am";
          jjStackUsername = "keeper";
        })
        (mkRepoCloneService pkgs cfg "grove-systems" "grove")
      ];
    };

  flake.modules.nixos.hermes-plumjam =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.hermes-agent;
    in
    {
      imports = [
        (mkHermesAgent "plumjam" {
          inherit
            config
            inputs
            lib
            pkgs
            ;
          personality = "kawaii";
          withKiwi = true;
          withLinear = true;
          withMealie = true;
          withX = true;
          gitUsername = "plum-9000";
          gitEmail = "plumbot@plumj.am";
          jjStackUsername = "plum-9000";
        })
        (mkRepoCloneService pkgs cfg "plumj-am" "nixos")
        (mkRepoCloneService pkgs cfg "grove-systems" "grove")
      ];
    };

  flake.modules.nixos.hermes-radka =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkForce;
    in
    {
      imports =
        singleton
        <| mkHermesAgent "radka" {
          inherit
            config
            inputs
            lib
            pkgs
            ;
          personality = "kawaii";
          withInstagram = true;
          withKiwi = true;
          withX = true;
          ghSkills = [ ];
          npmSkills = [ ];
          localSkills = [ ];
        };

      # Nicer experience for non-programmer use.
      services.hermes-agent.settings = {
        tool_loop_guardrails.non_interactive_hard_stop_enabled = mkForce false;
        approvals.mode = mkForce "off";
      };
    };

  flake.modules.common.ai-agents = self.modules.common.hermes-desktop;
  flake.modules.common.hermes-desktop =
    # {
    # inputs,
    # pkgs,
    # lib,
    # ...
    # }:
    # let
    # inherit (lib.lists) singleton;
    # in
    {
      # environment.systemPackages =
      #   singleton
      # TODO: Prefer from hermes repo but broken:
      # node-v43.4.1-headers.tar.gz> 100 336.6k 100 336.6k   0      0  1.44M      0                              0
      # error: hash mismatch in fixed-output derivation '/nix/store/rwn52jpnh40765ha2nhapccyhdxxwy39-node-v43.4.1-headers.tar.gz.drv':
      #          specified: sha256-f8bSbLRmtbP93CJAvEBs+sHWDZ1xP2bcpLhC1EnOmZU=
      #             got:    sha256-CyzcARd1+GhWr8ED7HBYW2MYD+tgetqZFMkaivaGvw0=
      # inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
      # TODO: bump
      # Electron version 41.10.6 is EOL
      # inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hermes-desktop;
    };
}
