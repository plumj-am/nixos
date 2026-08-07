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

      gerritMcpSrc = pkgs.fetchFromGitHub {
        owner = "GerritCodeReview";
        repo = "gerrit-mcp-server";
        rev = "e178cced87daf8467924a7b6b82c708d7c399207";
        sha256 = "1rvyp284kh85sr38i3ij5pgph427rzcbadxwbzjpjsb8i5c7zv9k";
      };

      # Skip flaky tests.
      pythonPkgs = pkgs.python312.pkgs.overrideScope (
        pfinal: pprev: {
          inline-snapshot = pprev.inline-snapshot.overridePythonAttrs (_: {
            doCheck = false;
          });
          mcp = pprev.mcp.overridePythonAttrs (_: {
            doCheck = false;
          });
        }
      );

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
        # store — every tool call crashes with "Permission denied". Point the
        # log at $HERMES_HOME (writable, hermes-owned; both host and
        # container contexts have it set) with /tmp as fallback.
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

        # Paths to env files (API keys, tokens) merged into
        # $HERMES_HOME/.env at activation. sops `hermes-env` secret
        # (secrets/all/ai.yaml) holds COMMANDCODE_API_KEY=<key>.
        environmentFiles = [ secrets."hermes-env".path ];

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
            command = "${gerritMcpServer}/bin/gerrit-mcp-server";
            args = [ ];
            env = {
              # ${HERMES_HOME} resolves per-context: the webui/desktop/CLI
              # run on the host (HERMES_HOME=/var/lib/hermes/.hermes) while
              # the gateway runs in the container (HERMES_HOME=/data/.hermes).
              # Both see the same config file, copied by hermes-mcp-config.
              GERRIT_CONFIG_PATH = "\${HERMES_HOME}/gerrit-mcp-config.json";
              # The server shells out to curl (run_curl → subprocess) and the
              # MCP env filter strips inherited PATH, so give it curl's bin
              # dir explicitly. Works in both host and container (both mount
              # /nix/store).
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
          pkgs.jq
          pkgs.nushell
          pkgs.python3

          pkgs.forgejo-mcp
          gerritMcpServer
        ];
        extraPlugins = [ ];

        container = {
          enable = true;
          backend = "docker";
          image = "ubuntu:24.04";
          extraVolumes = [ ];
          extraOptions = [ ];
          hostUsers = [ "jam" ];
        };
      };

      # Copy the gerrit MCP config into $HERMES_HOME (visible as /data/.hermes
      # inside the container) so the stdio MCP server spawned by the gateway
      # can read it. Runs as a oneshot BEFORE the gateway: the sops secret is
      # materialized by sops-install-secrets.service (sysinit.target), and
      # hermes-agent.service starts at multi-user.target, so ordering after
      # sops-install-secrets and before hermes-agent guarantees the file is
      # present when the gateway (and its MCP servers) come up.
      #
      # The gerrit-mcp-config sops secret is a JSON file:
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
            ${config.services.hermes-agent.stateDir}/.hermes/gerrit-mcp-config.json
        '';
      };

      # Restart the gateway when the gerrit config changes (MCP servers are
      # discovered at startup).

      # Ensure the gerrit config copy + git config complete before ANY gateway
      # start (including restartTriggers-driven restarts), not just boot.
      systemd.services.hermes-agent.after = [
        "hermes-mcp-config.service"
        "hermes-git-config.service"
      ];
      systemd.services.hermes-agent.wants = [
        "hermes-mcp-config.service"
        "hermes-git-config.service"
      ];
      systemd.services.hermes-agent.restartTriggers = [
        "${config.services.hermes-agent.stateDir}/.hermes/.env"
        "${config.services.hermes-agent.stateDir}/.hermes/gerrit-mcp-config.json"
      ];

      # Git config for the hermes user. The container mounts
      # ${stateDir}/home → /home/hermes (container HOME), and the host
      # hermes user's HOME is ${stateDir}; write ~/.gitconfig to both so the
      # gateway (container) and the webui/CLI (host) share the same identity.
      systemd.services.hermes-git-config = {
        description = "Write git config for hermes user";
        wantedBy = [ "hermes-agent.service" ];
        after = [ "sops-install-secrets.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.gitMinimal}/bin/git config --file ${config.services.hermes-agent.stateDir}/.gitconfig user.name "PlumJam"
          ${pkgs.gitMinimal}/bin/git config --file ${config.services.hermes-agent.stateDir}/.gitconfig user.email "git@plumj.am"
          ${pkgs.gitMinimal}/bin/git config --file ${config.services.hermes-agent.stateDir}/.gitconfig init.defaultBranch master
          ${pkgs.gitMinimal}/bin/git config --file ${config.services.hermes-agent.stateDir}/.gitconfig pull.rebase true
          ${pkgs.gitMinimal}/bin/git config --file ${config.services.hermes-agent.stateDir}/.gitconfig push.autoSetupRemote true

          # Same config in the container HOME (stateDir/home -> /home/hermes)
          install -d -o hermes -g hermes -m 0700 ${config.services.hermes-agent.stateDir}/home
          install -o hermes -g hermes -m 0600 \
            ${config.services.hermes-agent.stateDir}/.gitconfig \
            ${config.services.hermes-agent.stateDir}/home/.gitconfig
          chown hermes:hermes ${config.services.hermes-agent.stateDir}/.gitconfig
        '';
      };

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

      services.hermes-webui = {
        enable = true;
        user = "hermes";
        group = "hermes";
        host = "0.0.0.0";
        hermesHome = "/var/lib/hermes/.hermes";
        agent.package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
        environmentFiles = [ ];
      };

      # Auto-restart the webui when the shared .env changes (same pattern
      # as the gateway and serve services above).
      systemd.services.hermes-webui.restartTriggers = [
        "${config.services.hermes-agent.stateDir}/.hermes/.env"
      ];

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
