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
      mainModel ? "deepseek/deepseek-v4.1-flash",
      fallbackModel ? "meituan/LongCat-2.0:free",
      smallModel ? "meituan/LongCat-2.0:free",
      visionModel ? "Qwen/Qwen3.8-Flash",
      personality ? "concise",
      npmSkills ? config.ai.skills.npm,
      ghSkills ? config.ai.skills.gh,
      localSkills ? config.ai.skills.local,
      withInstagram ? false,
      withKiwi ? false,
      withLinear ? false,
      withMealie ? false,
      withX ? false,
      gitUsername ? "",
      gitEmail ? "",
      jjStackUsername ? "",
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists)
        singleton
        optional
        ;
      inherit (lib.meta) getExe;
      inherit (lib.attrsets) optionalAttrs genAttrs mapAttrs;
      inherit (lib.modules) mkForce mkIf;
      inherit (lib.strings) concatMapStringsSep optionalString;
      inherit (lib.trivial) flip const;
      inherit (config.sops) secrets;
      inherit (config.helpers) rustic;

      graftctl = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.graft-graftctl;
      jujutsu = inputs.jujutsu.packages.${pkgs.stdenv.hostPlatform.system}.jujutsu;
      jjStack = self.packages.${pkgs.stdenv.hostPlatform.system}.jj-stack;

      providerApi = "https://api.commandcode.ai/provider/v1";
      provider = "commandcode";
      commandcodeSubs = [
        1
        2
      ];

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
        "hindsight"
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
    in
    {
      imports = singleton inputs.hermes-agent.nixosModules.default;

      sops.secrets = {
        "hermes-shared-env" = {
          sopsFile = ../../secrets/services/hermes.yaml;
          owner = "hermes";
          group = "hermes";
          mode = "0400";
          restartUnits = singleton "hermes-auth-seed.service";
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
          fallback_providers = [
            {
              inherit provider;
              model = fallbackModel;
            }
            {
              provider = "opencode-free";
              model = "deepseek-v4-flash-free";
            }
            {
              provider = "nous";
              model = "meituan/longcat-2.0:free";
            }
            {
              provider = "nous";
              model = "poolside/laguna-s-2.1:free";
            }
          ];

          # no need to add commandcode provider - built-in now
          credential_pool_strategies.${provider} = "fill_first";
          auxiliary =
            mapAttrs (_: v: v // { inherit provider; })
            <|
              flip genAttrs
                (const {
                  model = mainModel;
                  fallback_chain = [
                    {
                      inherit provider;
                      model = fallbackModel;
                    }
                    {
                      provider = "opencode-free";
                      model = "deepseek-v4-flash-free";
                    }
                    {
                      provider = "nous";
                      model = "meituan/longcat-2.0:free";
                    }
                    {
                      provider = "nous";
                      model = "poolside/laguna-s-2.1:free";
                    }
                  ];
                })
                [
                  "review"
                  "triage_specifier"
                ]
              //
                flip genAttrs
                  (const {
                    model = smallModel;
                    fallback_chain = [
                      {
                        provider = "opencode-free";
                        model = "deepseek-v4-flash-free";
                      }
                      {
                        provider = "nous";
                        model = "meituan/longcat-2.0:free";
                      }
                      {
                        provider = "nous";
                        model = "poolside/laguna-s-2.1:free";
                      }
                    ];
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
            model_thresholds = {
              "deepseek-v4.1-flash" = 0.25; # ~250k
              "muse-spark-1.3" = 0.25; # ~250k
              "LongCat-2.0" = 0.25; # ~250k
              "Qwen3.8" = 0.25; # ~250k
            };
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

          # Gateway streaming
          streaming = {
            enabled = false;
            # transport = "edit";
            # edit_interval = 0.3;
            # buffer_threshold = 40;
            # cursor = " ▉";
          };

          skills = {
            creation_nudge_interval = 15; # remind to save skills every N iterations
            external_dirs = singleton "~/.agents/skills"; # read-only
          };

          agent = {
            max_turns = 500;
            verbose = false;
            reasoning_effort = "max"; # max | xhigh | high | medium | low | minimal | none
            reasoning_overrides = { }; # per-model: { "claude-opus-4.6" = "high"; }
            # gateway_timeout = 1800; # seconds, 0 for unlimited
            # gateway_timeout_warning = 900;
            api_max_retries = 5;
            # verify_on_stop = "auto"; # auto | true | false
            # coding_instructions = [ "Clean the diff before you commit." ];
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
            local = {
              model = "base"; # tiny | base | small | medium | large-v3 | turbo
            };
            openai = {
              model = "whisper-1";
              language = "";
            };
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

          delegation.max_iterations = 50;

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
        environment = { };

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
            # NOTE: ig-mcp has no pyproject and its setup.py console script
            # points at an `async def main()` (never awaited), so run the
            # module directly instead of the broken `instagram-mcp-server` exe.
            args = [
              "tool"
              "run"
              "--from"
              "git+https://github.com/jlbadano/ig-mcp"
              "python"
              "-m"
              "src.instagram_mcp_server"
            ];
            env = {
              INSTAGRAM_ACCESS_TOKEN = "\${INSTAGRAM_ACCESS_TOKEN}";
              FACEBOOK_APP_ID = "\${FACEBOOK_APP_ID}";
              FACEBOOK_APP_SECRET = "\${FACEBOOK_APP_SECRET}";
              INSTAGRAM_BUSINESS_ACCOUNT_ID = "\${INSTAGRAM_BUSINESS_ACCOUNT_ID}";
              LOG_LEVEL = "INFO";
              LOG_FILE = "";
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
          pkgs.unzip
          pkgs.whois
          pkgs.yq-go
          pkgs.zip
        ];
        extraPlugins = [ ];
      };

      # Seed both commandcode subs into each custom credential pool.
      # Direct auth.json write: `hermes auth add` appends a duplicate on
      # every run and leaks the key on the process cmdline. Idempotent:
      # only rewrites when entries differ, keeps counters and cooldowns.
      systemd.services.hermes-auth-seed = {
        description = "Seed hermes commandcode credential pools";
        after = singleton "sops-install-secrets.service";
        serviceConfig = oneshotServiceConfig;
        script = # python
          ''
            ${getExe pkgs.python3} - <<'PY'
            import json
            import os

            ENV_FILE = os.environ.get("HERMES_SEED_ENV_FILE", "${secrets."hermes-shared-env".path}")
            AUTH_JSON = os.environ.get("HERMES_SEED_AUTH_JSON", "${cfg.stateDir}/.hermes/auth.json")
            BASE_URL = "${providerApi}"
            POOL_KEY = "${provider}"
            SUBS = [int(n) for n in "${toString commandcodeSubs}".split()]
            STATUS_KEYS = ("last_status", "last_status_at", "last_error_code", "last_error_reason", "last_error_message", "last_error_reset_at")


            def load_keys(path):
                keys = {}
                with open(path, encoding="utf-8") as handle:
                    for raw in handle:
                        line = raw.strip()
                        if not line or line.startswith("#") or "=" not in line:
                            continue
                        if line.startswith("export "):
                            line = line[len("export "):].strip()
                        name, _, value = line.partition("=")
                        value = value.strip().strip('"').strip("'")
                        if len(value) >= 4:
                            keys[name.strip()] = value
                return keys


            keys = load_keys(ENV_FILE)
            names = [f"COMMANDCODE_{n}_API_KEY" for n in SUBS]
            missing = [name for name in names if name not in keys]
            if missing:
                raise SystemExit("hermes-auth-seed: missing in " + ENV_FILE + ": " + ", ".join(missing))

            try:
                with open(AUTH_JSON, encoding="utf-8") as handle:
                    store = json.load(handle)
            except (FileNotFoundError, json.JSONDecodeError) as exc:
                print("hermes-auth-seed: fresh store (" + exc.__class__.__name__ + ")")
                store = {}
            if not isinstance(store, dict):
                store = {}
            store.setdefault("version", 1)
            pools = store.get("credential_pool")
            if not isinstance(pools, dict):
                pools = {}
                store["credential_pool"] = pools

            changed = False
            old_entries = pools.get(POOL_KEY, [])
            if not isinstance(old_entries, list):
                old_entries = []
            old_by_label = {e.get("label"): e for e in old_entries if isinstance(e, dict)}
            entries = []
            for prio, n in enumerate(SUBS):
                label = f"sub-{n}"
                token = keys[f"COMMANDCODE_{n}_API_KEY"]
                old = old_by_label.get(label, {})
                entry = dict(old)
                entry.update({"id": old.get("id", label), "label": label, "auth_type": "api_key", "priority": prio, "source": "manual", "access_token": token, "base_url": BASE_URL})
                if old.get("access_token") == token:
                    entry.setdefault("request_count", 0)
                else:
                    entry["request_count"] = 0
                    for key in STATUS_KEYS:
                        entry.pop(key, None)
                entries.append(entry)
            dropped = sorted({e.get("label", "?") for e in old_entries if isinstance(e, dict)} - {e["label"] for e in entries})
            if dropped:
                print("hermes-auth-seed: dropping unmanaged " + POOL_KEY + ": " + ", ".join(dropped))
            if pools.get(POOL_KEY) != entries:
                pools[POOL_KEY] = entries
                changed = True

            if changed:
                os.makedirs(os.path.dirname(AUTH_JSON), exist_ok=True)
                tmp = AUTH_JSON + ".tmp"
                with open(tmp, "w", encoding="utf-8") as handle:
                    json.dump(store, handle, indent=2)
                    handle.write("\n")
                os.chmod(tmp, 0o600)
                os.replace(tmp, AUTH_JSON)
                print("hermes-auth-seed: wrote " + AUTH_JSON)
            else:
                print("hermes-auth-seed: no change")
            PY
          '';
      };

      users.users.hermes.linger = true;

      systemd.services.hermes-agent = {
        # Single place for pull and order: helpers run only when the
        # agent starts, and complete before it.
        after =
          singleton "hermes-auth-seed.service"
          ++ optional needsSkills "hermes-install-skills.service"
          ++ optional needsGitConfig "hermes-git-config.service";
        wants =
          singleton "hermes-auth-seed.service"
          ++ optional needsSkills "hermes-install-skills.service"
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
            inputs
            pkgs
            lib
            config
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
            inputs
            pkgs
            lib
            config
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
    in
    {
      imports =
        singleton
        <| mkHermesAgent "radka" {
          inherit
            inputs
            pkgs
            lib
            config
            ;
          personality = "kawaii";
          withInstagram = true;
          withKiwi = true;
          withX = true;
          ghSkills = [ ];
          npmSkills = [ ];
          localSkills = [ ];
        };
    };

  flake.modules.common.ai-agents = self.modules.common.hermes-desktop;
  flake.modules.common.hermes-desktop =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages =
        singleton
          # TODO: Prefer from hermes repo but broken:
          # node-v43.4.1-headers.tar.gz> 100 336.6k 100 336.6k   0      0  1.44M      0                              0
          # error: hash mismatch in fixed-output derivation '/nix/store/rwn52jpnh40765ha2nhapccyhdxxwy39-node-v43.4.1-headers.tar.gz.drv':
          #          specified: sha256-f8bSbLRmtbP93CJAvEBs+sHWDZ1xP2bcpLhC1EnOmZU=
          #             got:    sha256-CyzcARd1+GhWr8ED7HBYW2MYD+tgetqZFMkaivaGvw0=
          # inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hermes-desktop;
    };
}
