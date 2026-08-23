{
  flake.modules.nixos.hermes =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (config.myLib) mkRusticBackup;
      inherit (config.sops) secrets;
      inherit (config.ai.subs.commandcode) active;

      activeSubEnv = "COMMANDCODE_${toString active}";
      activeSub = "commandcode-${toString active}";

      cfg = config.services.hermes-agent;
      package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;

      gerritMcpSrc = pkgs.fetchFromGitHub {
        owner = "GerritCodeReview";
        repo = "gerrit-mcp-server";
        rev = "e178cced87daf8467924a7b6b82c708d7c399207";
        sha256 = "1rvyp284kh85sr38i3ij5pgph427rzcbadxwbzjpjsb8i5c7zv9k";
      };

      # Skip flaky tests.
      pythonPkgs = pkgs.python312.pkgs.overrideScope (
        _: pprev: {
          inline-snapshot = pprev.inline-snapshot.overridePythonAttrs (_: {
            doCheck = false;
          });
          mcp = pprev.mcp.overridePythonAttrs (_: {
            doCheck = false;
          });
        }
      );

      # No MemoryDenyWriteExecute (breaks CPython JIT-ish paths), read-only /
      # and home, private /tmp, pid-subset /proc.
      hermesHardening = {
        UMask = "0007";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectClock = true;
        LockPersonality = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        ProcSubset = "pid";
        ProtectProc = "invisible";
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

      gerritMcpServer = pythonPkgs.buildPythonPackage {
        pname = "gerrit-mcp-server";
        version = "1.0.0";
        src = gerritMcpSrc;
        pyproject = true;
        build-system = [
          pythonPkgs.setuptools
          pythonPkgs.wheel
        ];
        dependencies = [
          pythonPkgs.mcp
          pythonPkgs.uvicorn
          pythonPkgs.websockets
        ];
        # The upstream server writes server.log next to the package
        # (SERVER_ROOT_PATH / "server.log"), which is read-only in the Nix
        # store - every tool call crashes with "Permission denied". Point the
        # log at $HERMES_HOME (writable, hermes-owned) with /tmp as fallback.
        postPatch = ''
          substituteInPlace gerrit_mcp_server/main.py \
            --replace-fail \
              'LOG_FILE_PATH = SERVER_ROOT_PATH / "server.log"' \
              'LOG_FILE_PATH = Path(os.environ.get("HERMES_HOME") or "/tmp") / "gerrit-mcp-server.log"'
        '';
        meta = {
          description = "MCP server for interacting with Gerrit code review";
          homepage = "https://gerrit.googlesource.com/gerrit-mcp-server";
          license = lib.licenses.asl20;
          mainProgram = "gerrit-mcp-server";
        };
      };
    in
    {
      ai.secrets = true;

      imports = [
        inputs.hermes-agent.nixosModules.default
        inputs.hermes-webui.nixosModules.default
      ];

      services.rustic.backups.hermes = mkRusticBackup "hermes" {
        paths = singleton cfg.stateDir;
        exclude = [
          "${cfg.stateDir}/workspace/*/target"
          "${cfg.stateDir}/workspace/*/node_modules"
          "${cfg.stateDir}/workspace/*/result"
          "${cfg.stateDir}/.cargo"
        ];

        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      services.hermes-agent = {
        enable = true;
        inherit package;

        container.enable = false; # Run natively.

        user = "hermes";
        group = "hermes";
        createUser = true;
        stateDir = "/var/lib/hermes";
        workingDirectory = "/var/lib/hermes/workspace";

        # Declarative config.
        configFile = null;
        settings = {
          database.journal_mode = "wal";

          model = {
            default = "deepseek/deepseek-v4-flash";
            provider = activeSub;
            base_url = "https://api.commandcode.ai/provider/v1";
          };

          # Command Code provider - key resolved from .env.
          providers.commandcode = {
            name = "Command Code";
            api = "https://api.commandcode.ai/provider/v1";
            key_env = "${activeSubEnv}_API_KEY";
            models = [
              {
                id = "deepseek/deepseek-v4-flash";
                context_length = 1000000;
              }
              # TODO: limited input, wait until full release with full context
              {
                id = "poolside/laguna-s-2.1-free";
                context_length = 256000;
              }
              {
                id = "meta/muse-spark-1.2-contributor";
                context_length = 1048576;
              }
            ];
          };

          terminal = {
            backend = "local";
            # cwd = ""; controlled by `workingDirectory` above - do not set here
            timeout = 180;
            home_mode = "auto";
            lifetime_seconds = 300;
          };

          browser.inactivity_timeout = 120;

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
            # threshold = 0.25; # percentage
            threshold_tokens = 200000;
            idle_compact_after_seconds = 0; # >0 = compact after N s idle
            proactive_prune_tokens = 48000; # >0 = token trigger for tool-result prune
          };

          memory = {
            memory_enabled = true;
            user_profile_enabled = true;
          };

          # for messaging platforms
          session_reset = {
            mode = "none"; # none | idle | daily | both
            idle_minutes = 1440;
            at_hour = 4;
          };

          max_concurrent_sessions = null; # unlimited
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
            # external_dirs = [ "~/.agents/skills" ];  # read-only extra skill dirs
          };

          agent = {
            max_turns = 500;
            verbose = false;
            reasoning_effort = "max"; # max | xhigh | high | medium | low | minimal | none
            reasoning_overrides = { }; # per-model: { "claude-opus-4.6" = "high"; }
            # gateway_timeout = 1800; # seconds, 0 for unlimited
            # gateway_timeout_warning = 900;
            # api_max_retries = 3;
            # verify_on_stop = "auto"; # auto | true | false
            # coding_instructions = [ "Clean the diff before you commit." ];
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

          code_execution = {
            timeout = 300;
            max_tool_calls = 50;
          };

          delegation.max_iterations = 50;

          display = {
            personality = "concise";
            compact = false;
            tool_progress = "all"; # off | new | all | verbose | log
            cleanup_progress = false;
            interim_assistant_messages = true;
            long_running_notifications = true;
            busy_ack_detail = true;
            busy_input_mode = "interrupt"; # interrupt | queue | steer
            background_process_notifications = "all"; # off | result | error | all
            bell_on_complete = false;
            show_reasoning = false;
            streaming = true;
          };

          discord = {
            require_mention = true;
            auto_thread = true; # on mentions
            allow_mentions = {
              roles = true;
              users = true;
              replied_user = true;
            };
          };

          telemetry.shared_metrics.enabled = false;
        };

        environmentFiles = singleton secrets."hermes-env".path;

        # Non-secret env vars.
        environment = { };

        authFile = null;
        authFileForceOverwrite = false;

        documents = { };

        mcpServers = {
          forgejo = {
            command = "${pkgs.forgejo-mcp}/bin/forgejo-mcp";
            args = [
              "-t"
              "stdio"
              "-url"
              "https://git.plumj.am"
              "-token"
              "\${FORGEJO_MCP_TOKEN}"
            ];
            timeout = 120;
            connect_timeout = 60;
          };
          gerrit = {
            enabled = false;
            command = "${gerritMcpServer}/bin/gerrit-mcp-server";
            env = {
              GERRIT_CONFIG_PATH = "\${HERMES_HOME}/gerrit-mcp-config.json";
              # The server shells out to curl (run_curl -> subprocess) and the
              # MCP env filter strips inherited PATH, so give it curl's bin
              # dir explicitly.
              PATH = "${pkgs.curl}/bin";
            };
            timeout = 120;
            connect_timeout = 60;
          };
        };

        extraArgs = [ ]; # extra args for `hermes gateway`
        extraPackages = [
          pkgs.curl
          pkgs.gitMinimal
          pkgs.jujutsu
          pkgs.jq
          pkgs.nushell
          pkgs.python3

          pkgs.forgejo-mcp
          gerritMcpServer
        ];
        extraPlugins = [ ];

      };

      systemd.services.hermes-agent.serviceConfig = hermesHardening // {
        ProtectHome = lib.mkForce true; # Upstream doesn't set this...
      };

      # Example Gerrit MCP config:
      #   {
      #     "default_gerrit_base_url": "https://gerrit.plumj.am",
      #     "gerrit_hosts": [{
      #       "name": "plumj",
      #       "external_url": "https://gerrit.plumj.am",
      #       "authentication": { "type": "http_basic",
      #                           "username": "...", "auth_token": "..." }
      #     }]
      #   }
      systemd.services.hermes-mcp-config = {
        description = "Copy gerrit MCP config into HERMES_HOME";
        wantedBy = [ "hermes-agent.service" ];
        after = [ "sops-install-secrets.service" ];
        restartTriggers = [
          secrets."gerrit-mcp-config".path
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          install -o hermes -g hermes -m 0600 \
            ${secrets."gerrit-mcp-config".path} \
            ${cfg.stateDir}/.hermes/gerrit-mcp-config.json
        '';
      };

      # Restart the gateway when the gerrit config changes.

      # Ensure the gerrit config copy + git config complete before ANY gateway
      # starts.
      systemd.services.hermes-agent.after = [
        "hermes-mcp-config.service"
        "hermes-git-config.service"
      ];
      systemd.services.hermes-agent.wants = [
        "hermes-mcp-config.service"
        "hermes-git-config.service"
      ];
      systemd.services.hermes-agent.restartTriggers = [
        "${cfg.stateDir}/.hermes/.env"
        "${cfg.stateDir}/.hermes/gerrit-mcp-config.json"
      ];

      # Git config for the hermes user.
      systemd.services.hermes-git-config = {
        description = "Write git config for hermes user";
        wantedBy = [ "hermes-agent.service" ];
        after = [ "sops-install-secrets.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig user.name "Keeper"
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig user.email "keeper-bot@plumj.am"
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig init.defaultBranch master
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig pull.rebase true
          ${getExe pkgs.gitMinimal} config --file ${cfg.stateDir}/.gitconfig push.autoSetupRemote true
          chown hermes:hermes ${cfg.stateDir}/.gitconfig
        '';
      };

      # Desktop/dashboard backend (hermes serve).
      systemd.services.hermes-agent-serve = {
        description = "Hermes Agent backend (serve)";
        wantedBy = singleton "multi-user.target";
        after = singleton "hermes-agent.service";
        restartTriggers = singleton "${cfg.stateDir}/.hermes/.env";

        environment = {
          HOME = "${cfg.stateDir}";
          HERMES_HOME = "${cfg.stateDir}/.hermes";
          HERMES_MANAGED = "true";
        };

        serviceConfig = {
          Type = "simple";
          User = "hermes";
          Group = "hermes";
          WorkingDirectory = cfg.workingDirectory;

          ExecStart = "${package}/bin/hermes serve --host 0.0.0.0 --port 9119";

          Restart = "always";
          RestartSec = 5;
          TimeoutStopSec = 30;
        }
        // hermesHardening;
      };
      services.hermes-webui = {
        enable = true;
        user = "hermes";
        group = "hermes";
        host = "0.0.0.0";
        hermesHome = "/var/lib/hermes/.hermes";
        agent = {
          inherit package;
        };
        environmentFiles = [ ];
      };

      # Auto-restart the webui when the shared .env changes.
      systemd.services.hermes-webui.restartTriggers = singleton "${cfg.stateDir}/.hermes/.env";
    };
}
