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
      inherit (config.sops) secrets;
    in
    {
      imports = singleton inputs.hermes-agent.nixosModules.default;

      ai.secrets = true;

      services.hermes-agent = {
        enable = true;
        package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
        user = "hermes";
        group = "hermes";
        createUser = true;
        stateDir = "/var/lib/hermes";
        workingDirectory = "/var/lib/hermes/workspace";

        # Declarative config
        configFile = null;
        settings = {
          database.journal_mode = "wal";

          model = {
            default = "deepseek/deepseek-v4-flash";
            provider = "commandcode"; # named providers.commandcode entry below
            base_url = "https://api.commandcode.ai/provider/v1";
          };

          # Command Code provider — key resolved from .env via key_env
          providers.commandcode = {
            name = "Command Code";
            api = "https://api.commandcode.ai/provider/v1";
            key_env = "COMMANDCODE_API_KEY";
            models = [
              {
                id = "deepseek/deepseek-v4-flash";
                context_length = 1000000;
              }
              {
                id = "deepseek/deepseek-v4-pro";
                context_length = 1000000;
              }
              {
                id = "stepfun/Step-3.5-Flash";
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
            # cwd = controlled by `workingDirectory` above - do not set here
            timeout = 180;
            home_mode = "auto";
            docker_mount_cwd_to_workspace = false; # SECURITY: off by default
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
            reasoning_effort = "medium"; # xhigh | high | medium | low | minimal | none
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
              model = "whisper-1"; # whisper-1 | gpt-4o-mini-transcribe | …
              language = "";
            };
            # provider = "groq";
            # groq = { model = "whisper-large-v3-turbo"; };
            # mistral = { model = "voxtral-mini-latest"; };
          };

          code_execution = {
            timeout = 300; # max seconds per script
            max_tool_calls = 50; # max RPC tool calls per execution
          };

          delegation = {
            max_iterations = 50;
            # max_concurrent_children = 3;
            # max_spawn_depth = 1;
            # model = "google/gemini-3-flash-preview";  # empty = inherit parent
          };

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

          telemetry.shared_metrics.enabled = false;
        };

        # Paths to env files (API keys, tokens) merged into
        # $HERMES_HOME/.env at activation. sops `hermes-env` secret
        # (secrets/all/ai.yaml) holds COMMANDCODE_API_KEY=<key>.
        environmentFiles = [ secrets."hermes-env".path ];
        # Non-secret env vars. DO NOT put secrets here (world-readable).
        environment = { };

        authFile = null;
        authFileForceOverwrite = false;

        documents = { };
        mcpServers = { };

        extraArgs = [ ]; # extra args for `hermes gateway`
        extraPackages = [ ];
        extraPlugins = [ ];
        extraPythonPackages = [ ];
        extraDependencyGroups = [ ];

        restart = "always";
        restartSec = 5;

        # hermes CLI on PATH + HERMES_HOME system-wide (container routing)
        addToSystemPackages = true;

        container = {
          enable = true;
          backend = "docker";
          image = "ubuntu:24.04";
          extraVolumes = [ ];
          extraOptions = [ ];
          hostUsers = [ "jam" ];
        };
      };

      # Auto-restart the gateway when the merged .env changes.
      systemd.services.hermes-agent.restartTriggers = [
        "${config.services.hermes-agent.stateDir}/.hermes/.env"
      ];

      # Desktop / dashboard backend (hermes serve) - reachable over Tailscale.
      systemd.services.hermes-agent-serve = {
        description = "Hermes Agent backend (serve)";
        wantedBy = [ "multi-user.target" ];
        after = [
          "docker.service"
          "hermes-agent.service"
        ];
        requires = [ "docker.service" ];
        restartTriggers = [
          "${config.services.hermes-agent.stateDir}/.hermes/.env"
        ];
        preStart =
          let
            serveEntrypoint = pkgs.writeShellScript "hermes-serve-entrypoint" ''
              set -eu
              exec setpriv --reuid="''${HERMES_UID:?}" --regid="''${HERMES_GID:?}" --clear-groups "$@"
            '';
          in
          # bash
          ''
            # The gateway service (hermes-agent.service) creates the
            # current-package/current-entrypoint symlinks in preStart - wait
            # for them before creating this container.
            _attempt=0
            while [ $_attempt -lt 60 ]; do
              if [ -e ${config.services.hermes-agent.stateDir}/current-package ]; then
                break
              fi
              _attempt=$((_attempt + 1))
              sleep 1
            done
            # Install the minimal serve entrypoint into the shared volume
            install -m 0755 ${serveEntrypoint} ${config.services.hermes-agent.stateDir}/current-entrypoint-serve
            # Recreate on identity change (mirrors hermes-agent.service)
            _identity="container-serve-v3"
            _identity_file="${config.services.hermes-agent.stateDir}/.container-identity-serve"
            _need_create=false
            if ! ${getExe pkgs.docker} inspect hermes-agent-serve &>/dev/null; then
              _need_create=true
            elif [ ! -f "$_identity_file" ] || [ "$(cat "$_identity_file")" != "$_identity" ]; then
              echo "serve container config changed, recreating..."
              ${getExe pkgs.docker} rm -f hermes-agent-serve || true
              _need_create=true
            fi
            if [ "$_need_create" = "true" ]; then
              _uid=$(${pkgs.coreutils}/bin/id -u hermes)
              _gid=$(${pkgs.coreutils}/bin/id -g hermes)
              echo "Creating serve container..."
              ${getExe pkgs.docker} create \
                --name hermes-agent-serve \
                --network=host \
                --entrypoint /data/current-entrypoint-serve \
                --volume /nix/store:/nix/store:ro \
                --volume ${config.services.hermes-agent.stateDir}:/data \
                --volume ${config.services.hermes-agent.stateDir}/home:/home/hermes \
                --env HERMES_UID=$_uid \
                --env HERMES_GID=$_gid \
                --env HERMES_HOME=/data/.hermes \
                --env HERMES_MANAGED=true \
                --env HOME=/home/hermes \
                ${config.services.hermes-agent.container.image} \
                /data/current-package/bin/hermes serve --host 0.0.0.0 --port 9119
              echo "$_identity" > "$_identity_file"
            fi
          '';
        script = # bash
          ''
            exec ${getExe pkgs.docker} start -a hermes-agent-serve
          '';

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 5;
          TimeoutStopSec = 30;
        };
      };

      boot.kernelModules = [ "overlay" ];

      security.sudo.extraRules = singleton {
        users = singleton "jam";
        commands = singleton {
          command = "/run/current-system/sw/bin/docker";
          options = [ "NOPASSWD" ];
        };
      };
    };
}
