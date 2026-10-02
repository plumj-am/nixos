{ self, ... }:
{
  # Tern is a closed-beta Stencil Labs terminal multiplexer. Its tarball is
  # x86_64-linux only, so darwin hosts get no build.
  flake.modules.nixos.desktop = self.modules.nixos.tern;
  flake.modules.nixos.tern =
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

      prefix = "ctrl+g";
    in
    {
      # No unfree allowlist here: the package opens its own gate, because a
      # host's `unfree.allowedNames` never reaches a flake-level derivation.

      # gdbus, not the runtime lib: the wrapper's LD_LIBRARY_PATH cannot
      # help a missing program. Without it every window start logs
      # "cannot run a program program=\"gdbus\"" and
      # "cannot watch the settings portal", so the settings portal and
      # desktop integration never come up.
      environment.systemPackages = singleton self.packages.${pkgs.stdenv.hostPlatform.system}.tern
        # gdbus lives in the `bin` output; the default `out` has no bin/ at
        # all, so adding plain `glib` puts a library on PATH and nothing else.
        ++ [ pkgs.glib.bin ];

      hjemModule =
        { osConfig, config, ... }:
        let
          inherit (osConfig) theme;
        in
        {
          xdg.config.files."tern/settings.json" = {
            generator = pkgs.writers.writeJSON "tern-settings.json";
            type = "copy";
            value = {
              auto_update = false;

              theme = "System";
              theme_dark = "dark-gruvbox";
              theme_light = "light-sand";
              reduce_motion = "system";
              contrast = "Light";
              material = "Glass";
              opacity = 70;
              blur = 0;

              antialias = true;
              msaa = "off";
              sync_to_display = true;
              frame_latency = 2;

              layout = "Studio";
              status_bar = true;
              density = "Islands";
              pane_headers = "Never";

              native_surfaces = true;
              surface_headings = null;
              surface_diffs = "Split";
              surface_fold = true;
              surface_chat = "Reader";

              native_completion = true;
              native_editing = true;
              native_prompt = true;

              tabs = "Vertical";
              tabs_autohide = false;

              font_family = "${theme.font.mono.name} Light";
              font_size = theme.font.size.normal;

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
                getExe inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
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

                "alt+ctrl+h" = "move_pane:left";
                "alt+ctrl+j" = "move_pane:down";
                "alt+ctrl+k" = "move_pane:up";
                "alt+ctrl+l" = "move_pane:right";

                "${prefix}>ctrl+p" = "palette";
                "${prefix}>:" = "palette";

                "${prefix}>alt+shift+r" = "reload_config";
              };
            };
          };

          # The tern-ide plugin. tern reads ~/.config/tern/plugins/<id>/ for a
          # plugin.toml plus the window entry it names, so both files are
          # declared; the directory comes from the key, not from the source.
          xdg.config.files."tern/plugins/ide/plugin.toml".source =
            "${self.packages.${pkgs.stdenv.hostPlatform.system}.tern-ide-plugin}/plugin.toml";

          xdg.config.files."tern/plugins/ide/init.luau".source =
            "${self.packages.${pkgs.stdenv.hostPlatform.system}.tern-ide-plugin}/init.luau";
        };
    };
}
