{ self, ... }:
{
  # Tern, a closed-beta Stencil Labs multiplexer. Its tarball is x86_64-linux
  # only, so darwin hosts get no build.
  flake.modules.nixos.desktop = self.modules.nixos.tern;
  flake.modules.nixos.tern =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) attrNames optionalAttrs;
      inherit (lib.lists) filter singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkBefore mkForce;
      inherit (lib.strings) concatLines;
      inherit (config) theme;

      prefix = "ctrl+g";

      flakePackages = self.packages.${pkgs.stdenv.hostPlatform.system};

      # The login shell shim (packages/tern/tern.nix): bash for Tern's login
      # probe, nushell -- with the OSC 133;C payload Tern claims commands
      # from -- for everything else. The shim owns that payload, not this
      # module, because Tern starts a session's first pane and every pane it
      # restores with the login shell: the same shim serves the `shell`
      # setting below, so no pane can miss the payload.
      loginShell = "${flakePackages.tern-login-shell}/bin/nu";
    in
    {
      # Marks this host for every other host's `tern remote` host list.
      tern.installed = true;

      # No unfree allowlist: the package opens its own gate, since a host's
      # `unfree.allowedNames` never reaches a flake-level derivation.
      #
      environment.systemPackages = singleton flakePackages.tern;

      # Tern learns the login environment by probing `$SHELL` (see
      # packages/tern/tern.nix), and it links its own ~/.local/bin/tern and
      # desktop entries to the binary it runs, so launches skip the package
      # wrapper and the SHELL it sets. Give the shim to the session instead:
      # niri is a user service and takes its environment from the user
      # manager, so every process it starts -- Tern included -- answers the
      # probe.
      environment.variables.SHELL = mkForce loginShell;
      systemd.user.settings.Manager.DefaultEnvironment = [ "SHELL=${loginShell}" ];

      # The remote service can only answer before anyone logs in if jam's user
      # manager runs from boot, and that is a host's decision: a server nobody
      # logs into wants it (hosts/sloe.nix), a desktop has a session whenever
      # it is used. Off, the manager -- and the service with it -- starts at
      # the first login and stops when the last session ends. Set explicitly,
      # not with mkIf: `false` is what makes the activation switch lingering
      # off, and an unset option leaves it as `loginctl` left it.
      users.users.jam.linger = config.tern.remote.linger;

      hjemModule =
        { osConfig, config, ... }:
        {
          environment.sessionVariables.SHELL = mkForce loginShell;

          # `tern remote serve` is the network face of the session daemon: a
          # Tern on another machine logs in with a key from
          # ~/.ssh/authorized_keys and attaches to the sessions this machine
          # keeps, so its panes outlive the window and the screen.
          #
          # `tern remote install --user` writes this unit by hand, pinning a
          # store path that `nix store gc` can collect; declare it here so a
          # package bump carries the unit with it.
          #
          # Only for a user with a user manager: root's hjem user exists for
          # dotfiles and has no session to serve, and a host with another hjem
          # user (sloe's anamana) turns its manager off.
          systemd.services = optionalAttrs (config.user != "root" && config.systemd.enable) {
            tern-remote = {
              wantedBy = singleton "default.target";

              unitConfig = {
                Description = "Tern remote sessions (this user)";
                StartLimitIntervalSec = 60;
                StartLimitBurst = 10;
              };

              serviceConfig = {
                # Tern itself is the main process (the wrapper execs it), so a
                # stop signals it and it closes its sockets; the session daemon
                # it started keeps its panes.
                Type = "exec";
                # No --listen: UDP 8376 on every interface, which only the
                # tailnet reaches, because the firewall trusts tailscale0
                # alone. --no-iroh keeps the endpoint id off Stencil's relay:
                # every client reaches this host over the tailnet instead.
                # No --state-dir either: its default is the config directory,
                # where the host key clients pin already lives, and
                # `tern remote doctor --host` reads this line and cannot expand
                # a specifier.
                ExecStart = "${getExe flakePackages.tern} remote serve --user --no-iroh";
                Restart = "on-failure";
                RestartSec = 2;
                # Bad arguments do not fix themselves by restarting.
                RestartPreventExitStatus = 2;
                KillMode = "process";
                TimeoutStopSec = 10;
              };
            };
          };

          # Tern builds a session's first pane, and every pane it restores,
          # before its login-environment capture is known, and starts them with
          # the libc default PATH. Put the profile directories back when they
          # are missing -- before carapace.nu (sourced by
          # modules/nushell/completions.nix) reads $env.PATH.
          xdg.config.files."nushell/config.nu".text =
            mkBefore
              # nu
              ''
                let path = ($env.PATH? | default [])
                if ("/run/current-system/sw/bin" not-in $path) {
                  $env.PATH = ($path | append [
                    "/run/wrappers/bin"
                    # $env.USER is not guaranteed, and when it is missing the
                    # whole config fails to load. $nu.home-dir falls back to
                    # passwd, so its last component is always the user name.
                    $"/etc/profiles/per-user/($nu.home-dir | path basename)/bin"
                    "/nix/var/nix/profiles/default/bin"
                    "/run/current-system/sw/bin"
                  ])
                }
              '';

          xdg.config.files."tern/settings.json" = {
            generator = pkgs.writers.writeJSON "tern-settings.json";
            type = "copy";
            value = {
              auto_update = false;
              desktop_integration = true;

              theme = "System";
              theme_dark = "dark-gruvbox";
              theme_light = "light-honeycomb"; # gruvbox is ass, way too yellow
              reduce_motion = "system";
              contrast = "Off"; # automatic contrast correction
              material = "Glass";
              opacity = 70;
              blur = 0;
              padding_x = 6;
              padding_y = 6;

              antialias = true;
              msaa = "off";
              sync_to_display = false;
              frames_queued = 1;

              layout = "Rail";
              status_bar = true;
              density = "Islands";
              pane_headers = "Never";
              system_title_bar = true;

              native_surfaces = true;
              surface_headings = null;
              surface_diffs = "Split";
              surface_fold = true;
              surface_chat = "Spine";
              keep_composer_open = true;

              native_completion = true;
              native_editing = true;
              native_prompt = true;

              tabs = "Vertical";
              tabs_autohide = false;

              cursor.shape = null;
              cursor.blink = false;
              cursor.programs = true;

              carly.model = "@smol";
              carly.heartbeat = 10;

              clawdi = true;

              font_family = theme.font.mono.name;
              code_font = theme.font.mono.name;
              browse_font = theme.font.mono.name;
              editor_font = theme.font.mono.name;
              ui_font = theme.font.sans.name;
              font_size = theme.font.size.normal;
              font_weight = 300;

              scrollback_lines = 200000;

              copy_on_select = true;
              smooth_scroll = true;
              overscroll = true;

              link_click = "Command"; # open links with ctrl+click
              link_target = "Browser"; # open in external browser
              hyperlinks = "allow";

              clipboard_write = "allow";

              notifications = true;
              notification_filters = [ ];

              paste = {
                quote_urls_at_prompt = true;
                confirm = true;
                confirm_if_large = false;
                replace_dangerous_control_codes = false;
                replace_newline = false;
              };

              confirm_close = "running_programs";

              shell = "${loginShell}";
              agent_command = "${getExe flakePackages.omp-wrapped}";

              command_lenses = true;
              program_colors = false; # use tern palette
              composer_text = "Markdown";
              prompt_style = "imported";
              new_tabs = "Focused";
              new_blocks = "Shell";
              agent_placement = "split";
              cross_session_click = "switch";
              reconnect_hosts = true;
              # Serve this machine's sessions to remote clients; off, they still
              # connect but get sessions of their own.
              share_sessions = true;
              ask_to_move = true;
              prefs_width = 440;

              agents = {
                notify_needs_attention = true;
                notify_turn_finished = true;
              };

              files = {
                markdown_rendered = true;
                wrap_code = false;
                wrap_prose = true;
                line_numbers = true;
                tab_width = 4;
                auto_save = "off";
                attachments = "";
              };
              file_tree = {
                open = false;
                width = 256;
                hidden = true;
                ignored = true;
                search_ignored = false;
                compact = true;
                reveal = true;
                preview_click = false;
              };
              git = {
                auto_fetch_minutes = 0;
                auto_prune = true;
                default_branch_name = "master";
                pull_mode = "FastForward";
                initial_commits = 500;
                lazy_load_commits = true;
                profiles = [ ];
                profile = null;
                use_local_ssh_agent = true;
                ssh_private_key = "~/.ssh/id";
                ssh_public_key = "~/.ssh/id.pub";
                external_editor = "${getExe pkgs.steelix}";
                gpg_program = "";
                gpg_key_id = "";
                sign_commits_by_default = true;
                sign_tags_by_default = true;
                notify_operation_success = true;
                notify_operation_failure = true;
                use_git_executable = true;
                git_executable = "${getExe pkgs.gitMinimal}";
                show_commit_author = false;
                show_commit_date = true;
                show_commit_sha = true;
                encoding = "Utf8";
                sidebar_folded = [ ];
                ref_column_width = 180.0;
                graph_column_width = null;
                message_column_width = 420.0;
                inspector_width = 360.0;
                diff_split = true;
                diff_file_view = false;
                diff_hunk_view = false;
                diff_wrap = false;
                diff_whitespace = "Exact";
                path_tree = false;
                ai_model = "";
              };

              sqlite = { };

              notebook = { };

              keymap = "tmux";
              keymap_prefix = prefix;
              swap_ctrl_cmd = false;
              option_as_alt = "auto";
              keybinds = {
                "${prefix}>left" = [ ];
                "ctrl+alt+shift+left" = [ ];
                "alt+h" = "focus_pane:left";
                "${prefix}>down" = [ ];
                "ctrl+alt+shift+down" = [ ];
                "alt+j" = "focus_pane:down";
                "${prefix}>up" = [ ];
                "ctrl+alt+shift+up" = [ ];
                "alt+k" = "focus_pane:up";
                "${prefix}>right" = [ ];
                "ctrl+alt+shift+right" = [ ];
                "alt+l" = "focus_pane:right";

                "${prefix}>z" = [ ];
                "ctrl+shift+r" = [ ];
                "alt+f" = "zoom";

                "${prefix}>p" = [ ];
                "ctrl+shift+left" = [ ];
                "alt+shift+k" = "previous_tab";

                "${prefix}>n" = [ ];
                "ctrl+shift+right" = [ ];
                "alt+shift+j" = "next_tab";

                "${prefix}>ctrl+d" = "split_down";
                "${prefix}>ctrl+r" = "split_right";
                "${prefix}>x" = "close_pane";

                "${prefix}>shift+r" = "rename_tab";
                "${prefix}>b" = "toggle_sidebar";
                "${prefix}>shift+X" = "close_tab";

                "alt+ctrl+h" = "move_pane:left";
                "alt+ctrl+j" = "move_pane:down";
                "alt+ctrl+k" = "move_pane:up";
                "alt+ctrl+l" = "move_pane:right";

                "${prefix}>ctrl+p" = "palette";
                "ctrl+shift+p" = "palette";
                "${prefix}>:" = "palette";

                "${prefix}>i" = "inbox";
                "ctrl+shift+i" = "inbox";

                "${prefix}>a" = "plugin.jj.open";
                "${prefix}>shift+a" = "plugin.jj.create";
                "${prefix}>alt+a" = "plugin.jj.remove";

                "${prefix}>l" = "plugin.ide.layout";

                "${prefix}>g" = "plugin.tools.jjui";
                "${prefix}>d" = "plugin.tools.hunk";
                "${prefix}>c" = "plugin.tools.copse";
              };
            };
          };

          # The hosts `tern remote` offers to attach to: every other host that
          # includes this module, read from the marker each one sets. The marker is
          # a constant, and only this list reads it, so evaluating another host's
          # configuration stops at that option instead of recursing into its copy
          # of this list.
          xdg.config.files."tern/hosts".text =
            concatLines
            <| filter (
              name:
              name != osConfig.networking.hostName
              && (self.nixosConfigurations.${name}.config.tern.installed or false)
            )
            <| attrNames self.nixosConfigurations;

          xdg.config.files."tern/clawdi/settings.json" = {
            generator = pkgs.writers.writeJSON "tern-clawdi-settings.json";
            value = {
              petPosition = {
                x = 1700.0;
                y = -140.0;
              };
              petSize = 20;
              skin = "cat";
              stretchIntervalMin = 9999; # idk how to turn it off
              taskCompleteSoundVolume = 0.0;
            };
          };

          xdg.config.files."tern/clawdi/pattern.json" = {
            generator = pkgs.writers.writeJSON "tern-clawdi-pattern.json";
            value = {
              baseColor = "#1A1A1A";
              body = [ ];
              earL = [ ];
              earR = [ ];
              eyeBgColor = "#FFFFFF";
              eyeColor = "#1A1A1A";
              eyeColorLeft = "#1A1A1A";
              eyeColorRight = "#1A1A1A";
              head = [ ];
              legFl = [ ];
              legFr = [ ];
              legRl = [ ];
              legRr = [ ];
              oddEye = false;
              outlineColor = "#FFFFFF";
              selectedPresetId = "black-cat";
              tail = [ ];
            };
          };

          xdg.config.files."tern/carly/HEARTBEAT.md".text = # markdown
            ''
              - Tell me if a pane shows a build failure, say which.
              - If an agent has stopped but has unread advisor notices, tell it to check them.
              - If an agent has stopped due to an error, tell it to "continue", say which. If the
                error occurs >3 times consecutively with no progress made, notify me.
            '';

          # tern reads ~/.config/tern/plugins/<id>/ for a plugin.toml plus the
          # entries it names; the directory comes from the key, not the source.
          xdg.config.files."tern/plugins/ide/plugin.toml".source =
            "${flakePackages.tern-ide-plugin}/plugin.toml";

          xdg.config.files."tern/plugins/ide/init.luau".source = "${flakePackages.tern-ide-plugin}/init.luau";

          xdg.config.files."tern/plugins/jj/plugin.toml".source =
            "${flakePackages.tern-jj-plugin}/plugin.toml";

          xdg.config.files."tern/plugins/jj/init.luau".source = "${flakePackages.tern-jj-plugin}/init.luau";

          xdg.config.files."tern/plugins/jj/window.luau".source =
            "${flakePackages.tern-jj-plugin}/window.luau";

          xdg.config.files."tern/plugins/tools/plugin.toml".source =
            "${flakePackages.tern-tools-plugin}/plugin.toml";

          xdg.config.files."tern/plugins/tools/init.luau".source =
            "${flakePackages.tern-tools-plugin}/init.luau";

          xdg.config.files."tern/plugins/links/plugin.toml".source =
            "${flakePackages.tern-links-plugin}/plugin.toml";

          xdg.config.files."tern/plugins/links/init.luau".source =
            "${flakePackages.tern-links-plugin}/init.luau";

          xdg.config.files."tern/plugins/tab-status/plugin.toml".source =
            "${flakePackages.tern-tab-status-plugin}/plugin.toml";

          xdg.config.files."tern/plugins/tab-status/init.luau".source =
            "${flakePackages.tern-tab-status-plugin}/init.luau";

          xdg.config.files."tern/plugins/rail-band/plugin.toml".source =
            "${flakePackages.tern-rail-band-plugin}/plugin.toml";

          xdg.config.files."tern/plugins/rail-band/init.luau".source =
            "${flakePackages.tern-rail-band-plugin}/init.luau";

          xdg.config.files."tern/plugins/rail-band/rail-band.css".source =
            "${flakePackages.tern-rail-band-plugin}/rail-band.css";

          xdg.config.files."tern/plugins/chime/plugin.toml".source =
            "${flakePackages.tern-chime-plugin}/plugin.toml";

          xdg.config.files."tern/plugins/chime/sounds.toml" = {
            generator = pkgs.writers.writeTOML "tern-plugins-chime-sounds.toml";
            value = {
              only_unfocused = false;
              min_seconds = 30; # for shell command notifications

              alert = "sounds/alert.wav";
              yield = "sounds/yield.wav";
              done = "sounds/done.wav";
            };
          };

          xdg.config.files."tern/plugins/chime/src/window.luau".source =
            "${flakePackages.tern-chime-plugin}/src/window.luau";

          xdg.config.files."tern/plugins/chime/scripts/play.vbs".source =
            "${flakePackages.tern-chime-plugin}/scripts/play.vbs";

          xdg.config.files."tern/plugins/chime/sounds/alert.wav".source =
            "${flakePackages.tern-chime-plugin}/sounds/alert.wav";

          xdg.config.files."tern/plugins/chime/sounds/done.wav".source =
            "${flakePackages.tern-chime-plugin}/sounds/done.wav";

          xdg.config.files."tern/plugins/chime/sounds/yield.wav".source =
            "${flakePackages.tern-chime-plugin}/sounds/yield.wav";
        };
    };
}
