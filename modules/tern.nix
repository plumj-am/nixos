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
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkBefore mkForce;
      inherit (config) theme;

      prefix = "ctrl+g";

      # The login shell shim (packages/tern/tern.nix): bash for Tern's login
      # probe, nushell for everything else.
      loginShell = "${self.packages.${pkgs.stdenv.hostPlatform.system}.tern-login-shell}/bin/nu";
    in
    {
      # No unfree allowlist: the package opens its own gate, since a host's
      # `unfree.allowedNames` never reaches a flake-level derivation.

      environment.systemPackages = singleton self.packages.${pkgs.stdenv.hostPlatform.system}.tern;

      # Tern learns the login environment by probing `$SHELL` (see
      # packages/tern/tern.nix), and it links its own ~/.local/bin/tern and
      # desktop entries to the binary it runs, so launches skip the package
      # wrapper and the SHELL it sets. Give the shim to the session instead:
      # niri is a user service and takes its environment from the user
      # manager, so every process it starts -- Tern included -- answers the
      # probe.
      environment.variables.SHELL = mkForce loginShell;
      systemd.user.settings.Manager.DefaultEnvironment = [ "SHELL=${loginShell}" ];

      hjemModule = {
        environment.sessionVariables.SHELL = mkForce loginShell;

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

            theme = "System";
            theme_dark = "dark-gruvbox";
            theme_light = "light-honeycomb"; # gruvbox is ass, way too yellow
            reduce_motion = "system";
            contrast = "Off"; # automatic contrast correction
            material = "Glass";
            opacity = 70;
            blur = 0;

            antialias = true;
            msaa = "off";
            sync_to_display = false;
            frame_latency = 1;

            layout = "Studio";
            status_bar = true;
            density = "Islands";
            pane_headers = "Never";
            system_title_bar = true;

            native_surfaces = true;
            surface_headings = null;
            surface_diffs = "Split";
            surface_fold = true;
            surface_chat = "Spine";

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

            link_click = "Click";
            link_target = "Tern";
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

            shell = "${getExe pkgs.nushell}";
            agent_command = "PI_OMP_NATIVE=1 ${
              getExe self.packages.${pkgs.stdenv.hostPlatform.system}.omp-wrapped
            }";

            command_lenses = true;
            program_colors = true;
            composer_text = "Markdown";
            prompt_style = "imported";
            new_tabs = "Focused";
            new_blocks = "Shell";
            agent_placement = "split";
            cross_session_click = "switch";
            reconnect_hosts = true;
            ask_to_move = true;
            prefs_width = 440;

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
              auto_fetch_minutes = 5;
              auto_prune = true;
              default_branch_name = "master";
              pull_mode = "FastForward";
              initial_commits = 500;
              lazy_load_commits = true;
              profiles = [ ];
              profile = null;
              use_local_ssh_agent = true;
              ssh_private_key = "";
              ssh_public_key = "";
              external_editor = "hx";
              gpg_program = "";
              gpg_key_id = "";
              sign_commits_by_default = false;
              sign_tags_by_default = false;
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
            };
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
        xdg.config.files."tern/plugins/ide/plugin.toml".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tern-ide-plugin
        }/plugin.toml";

        xdg.config.files."tern/plugins/ide/init.luau".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tern-ide-plugin
        }/init.luau";

        xdg.config.files."tern/plugins/jj/plugin.toml".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tern-jj-plugin
        }/plugin.toml";

        xdg.config.files."tern/plugins/jj/host.luau".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tern-jj-plugin
        }/host.luau";

        xdg.config.files."tern/plugins/jj/init.luau".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tern-jj-plugin
        }/init.luau";

        xdg.config.files."tern/plugins/jj/window.luau".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tern-jj-plugin
        }/window.luau";

        xdg.config.files."tern/plugins/tools/plugin.toml".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tern-tools-plugin
        }/plugin.toml";

        xdg.config.files."tern/plugins/tools/init.luau".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tern-tools-plugin
        }/init.luau";

      };
    };
}
